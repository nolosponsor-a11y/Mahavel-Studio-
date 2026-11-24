// Server-only Edge Function. Never place service_role key or cron secret in the PWA.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.10';

Deno.serve(async req => {
  const secret = Deno.env.get('MAHAVEL_CLEANUP_SECRET');
  if (!secret || req.headers.get('x-mahavel-cron-secret') !== secret) {
    return new Response('Forbidden', { status: 403 });
  }
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return new Response('Server configuration missing', { status: 500 });
  const sb = createClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } });
  const now = new Date().toISOString();
  // Remove in small batches; next scheduled invocation handles remaining files.
  const { data, error } = await sb.from('documents')
    .select('id,storage_path,expires_at,keep')
    .eq('keep', false).lt('expires_at', now).order('expires_at').limit(100);
  if (error) return Response.json({ error: error.message }, { status: 500 });
  let removed = 0;
  const failures: string[] = [];
  for (const item of data ?? []) {
    // Recheck after listing: a user might have marked the file "À conserver".
    const fresh = await sb.from('documents').select('keep,expires_at,storage_path').eq('id',item.id).maybeSingle();
    if (fresh.error || !fresh.data || fresh.data.keep || fresh.data.expires_at >= now) continue;
    const storage = await sb.storage.from('studio-private').remove([fresh.data.storage_path]);
    if (storage.error) { failures.push(item.id); continue; }
    const deleted = await sb.from('documents').delete().eq('id',item.id).eq('keep',false).lt('expires_at',now);
    if (deleted.error) failures.push(item.id); else removed++;
  }
  return Response.json({ scanned: data?.length ?? 0, removed, failed: failures.length, failures });
});
