import { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from './config.js';
let client;
export async function db(){if(!client){const {createClient}=await import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49.10/+esm');client=createClient(SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}})}return client}
export const configured=()=>!SUPABASE_URL.includes('VOTRE-PROJET')&&!SUPABASE_PUBLISHABLE_KEY.includes('VOTRE_CLE');
export async function query(table,workspace,select='*',sort='created_at'){const s=await db();let q=s.from(table).select(select).eq('workspace_id',workspace).limit(150);if(sort)q=q.order(sort,{ascending:false});const {data,error}=await q;if(error)throw error;return data}
export async function mutate(table,record,id){const s=await db();const result=id?await s.from(table).update(record).eq('id',id).select().single():await s.from(table).insert(record).select().single();if(result.error)throw result.error;return result.data}
export async function remove(table,id){const s=await db();const {error}=await s.from(table).delete().eq('id',id);if(error)throw error}
