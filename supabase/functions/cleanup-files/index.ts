// Fonction Edge réservée aux appels avec secret CRON_SECRET en Authorization: Bearer.
// Déployer avec --no-verify-jwt si l'invocation utilise CRON_SECRET.
import { createClient } from 'npm:@supabase/supabase-js@2';
Deno.serve(async req => {
  const expected=Deno.env.get('CRON_SECRET');
  if (!expected || req.headers.get('authorization')!==`Bearer ${expected}`) return new Response('Forbidden',{status:403});
  const url=Deno.env.get('SUPABASE_URL');const key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if(!url||!key)return new Response('Missing server configuration',{status:500});
  const client=createClient(url,key,{auth:{persistSession:false}});
  const {data:files,error}=await client.from('documents').select('id,storage_path').eq('keep',false).lt('expires_at',new Date().toISOString()).limit(100);
  if(error)return new Response(error.message,{status:500});
  let deleted=0,errors=[];
  for(const file of files||[]){
    // Protection revérifiée immédiatement avant suppression ; exécution séquentielle.
    const {data:f,error:readErr}=await client.from('documents').select('keep,expires_at').eq('id',file.id).maybeSingle();
    if(readErr||!f||f.keep||new Date(f.expires_at)>new Date())continue;
    const rem=await client.storage.from('studio-private').remove([file.storage_path]);
    if(rem.error){errors.push({id:file.id,error:rem.error.message});continue}
    const db=await client.from('documents').delete().eq('id',file.id).eq('keep',false).lt('expires_at',new Date().toISOString());
    if(db.error){errors.push({id:file.id,error:db.error.message});continue}deleted++;
  }
  return Response.json({scanned:files?.length||0,deleted,errors});
});
