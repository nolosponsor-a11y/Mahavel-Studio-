-- MAHAVEL STUDIO 0.4.0 — ADDITIVE ONLY. Review before applying to production.
begin;

create table if not exists public.conversation_reads (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key(conversation_id,user_id)
);
alter table public.conversation_reads enable row level security;
grant select,insert,update on public.conversation_reads to authenticated;
drop policy if exists conversation_reads_own_select on public.conversation_reads;
create policy conversation_reads_own_select on public.conversation_reads for select to authenticated
using(user_id=(select auth.uid()) and public.can_view_conversation(conversation_id));
drop policy if exists conversation_reads_own_insert on public.conversation_reads;
create policy conversation_reads_own_insert on public.conversation_reads for insert to authenticated
with check(user_id=(select auth.uid()) and public.can_view_conversation(conversation_id));
drop policy if exists conversation_reads_own_update on public.conversation_reads;
create policy conversation_reads_own_update on public.conversation_reads for update to authenticated
using(user_id=(select auth.uid()) and public.can_view_conversation(conversation_id))
with check(user_id=(select auth.uid()) and public.can_view_conversation(conversation_id));

alter table public.tasks add column if not exists import_key text;
alter table public.events add column if not exists import_key text;
alter table public.profile_schedules add column if not exists import_key text;
create unique index if not exists tasks_import_dedupe on public.tasks(workspace_id,import_key);
create unique index if not exists events_import_dedupe on public.events(workspace_id,import_key);
create unique index if not exists schedules_import_dedupe on public.profile_schedules(workspace_id,import_key);

create table if not exists public.studio_calls (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null references public.workspaces(id),
 conversation_id uuid not null references public.conversations(id) on delete cascade,
 caller_id uuid not null references auth.users(id),
 callee_id uuid not null references auth.users(id),
 media_kind text not null check(media_kind in ('audio','video')),
 status text not null default 'ringing' check(status in ('ringing','connected','declined','ended')),
 offer jsonb check(offer is null or length(offer::text)<65536), answer jsonb check(answer is null or length(answer::text)<65536),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint no_self_call check(caller_id<>callee_id)
);
create index if not exists studio_calls_incoming on public.studio_calls(callee_id,created_at desc) where status='ringing';
alter table public.studio_calls enable row level security;
grant select,insert,update on public.studio_calls to authenticated;
drop policy if exists calls_party_select on public.studio_calls;
create policy calls_party_select on public.studio_calls for select to authenticated
using((caller_id=(select auth.uid()) or callee_id=(select auth.uid())) and public.can_view_conversation(conversation_id));
drop policy if exists calls_party_insert on public.studio_calls;
create policy calls_party_insert on public.studio_calls for insert to authenticated
with check(caller_id=(select auth.uid()) and public.can_view_conversation(conversation_id)
 and exists(select 1 from public.conversation_members cm where cm.conversation_id=studio_calls.conversation_id and cm.user_id=studio_calls.callee_id)
 and exists(select 1 from public.conversations c where c.id=conversation_id and c.workspace_id=studio_calls.workspace_id and c.kind='Direct'));
drop policy if exists calls_party_update on public.studio_calls;
create policy calls_party_update on public.studio_calls for update to authenticated
using((caller_id=(select auth.uid()) or callee_id=(select auth.uid())) and public.can_view_conversation(conversation_id))
with check((caller_id=(select auth.uid()) or callee_id=(select auth.uid())) and public.can_view_conversation(conversation_id));
create or replace function public.studio_call_guard() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if new.id is distinct from old.id or new.workspace_id is distinct from old.workspace_id
 or new.conversation_id is distinct from old.conversation_id or new.caller_id is distinct from old.caller_id
 or new.callee_id is distinct from old.callee_id or new.media_kind is distinct from old.media_kind
 or new.offer is distinct from old.offer or new.created_at is distinct from old.created_at
 then raise exception 'Immutable call fields'; end if;
 if old.status in ('ended','declined') then raise exception 'Call already closed'; end if;
 if new.answer is distinct from old.answer and (select auth.uid())<>old.callee_id then raise exception 'Only callee may answer'; end if;
 if new.status='connected' and ((select auth.uid())<>old.callee_id or new.answer is null) then raise exception 'Only callee may accept'; end if;
 new.updated_at=now(); return new;
end $$;
drop trigger if exists studio_call_guard_update on public.studio_calls;
create trigger studio_call_guard_update before update on public.studio_calls for each row execute function public.studio_call_guard();

-- Trickle ICE buffered as database records. Per-party access only.
create table if not exists public.studio_call_candidates (
 id bigint generated always as identity primary key,
 call_id uuid not null references public.studio_calls(id) on delete cascade,
 sender_id uuid not null references auth.users(id),
 candidate jsonb not null,
 created_at timestamptz not null default now()
);
create index if not exists studio_call_candidates_by_call on public.studio_call_candidates(call_id,id);
alter table public.studio_call_candidates enable row level security;
grant select,insert on public.studio_call_candidates to authenticated;
grant usage, select on sequence public.studio_call_candidates_id_seq to authenticated;
drop policy if exists call_candidates_read on public.studio_call_candidates;
create policy call_candidates_read on public.studio_call_candidates for select to authenticated using(
 exists(select 1 from public.studio_calls c where c.id=studio_call_candidates.call_id and
 (c.caller_id=(select auth.uid()) or c.callee_id=(select auth.uid()))));
drop policy if exists call_candidates_send on public.studio_call_candidates;
create policy call_candidates_send on public.studio_call_candidates for insert to authenticated with check(
 sender_id=(select auth.uid()) and jsonb_typeof(candidate)='object' and length(candidate::text)<8192 and
 exists(select 1 from public.studio_calls c where c.id=studio_call_candidates.call_id and
 (c.caller_id=(select auth.uid()) or c.callee_id=(select auth.uid())) and c.status in ('ringing','connected')));

-- Harden access to unrelated users' notifications. Existing table policies may already cover this.
-- Reminder: no Storage files are deleted by this SQL. Deployment of the Edge Function is required.

-- System-generated notifications for assignees; no client-side ability to forge them.
create or replace function public.notify_task_change() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.assignee_id is not null and (tg_op='INSERT' or new.assignee_id is distinct from old.assignee_id or new.status is distinct from old.status) and
 exists(select 1 from public.memberships m where m.workspace_id=new.workspace_id and m.user_id=new.assignee_id)
 then
  insert into public.notifications(workspace_id,user_id,title,body)
  values(new.workspace_id,new.assignee_id,
   case when new.status='À valider' then 'Validation demandée' when new.status='Corrections demandées' then 'Corrections demandées' else 'Tâche actualisée' end,
   left(new.title,200));
 end if;
 return new;
end $$;
drop trigger if exists notify_task_after_change on public.tasks;
create trigger notify_task_after_change after insert or update of assignee_id,status on public.tasks
for each row execute function public.notify_task_change();
revoke all on function public.notify_task_change() from public,anon,authenticated;

-- Keep the database responsible for read-receipt uniqueness; no duplicate marks.

-- Atomic review: prevents a validation record from being written without the task update.
create or replace function public.review_studio_task(p_task uuid,p_approve boolean,p_comment text)
returns void language plpgsql security invoker set search_path='' as $$
declare v_task public.tasks%rowtype;
begin
 select * into v_task from public.tasks where id=p_task for update;
 if not found then raise exception 'Tâche introuvable'; end if;
 if not public.is_manager(v_task.workspace_id) then raise exception 'Validation réservée aux responsables'; end if;
 if v_task.status<>'À valider' then raise exception 'La tâche n’est plus en attente de validation'; end if;
 if not p_approve and length(trim(coalesce(p_comment,'')))=0 then raise exception 'Commentaire obligatoire'; end if;
 update public.tasks set status=case when p_approve then 'Terminé' else 'Corrections demandées' end where id=p_task;
 insert into public.approvals(workspace_id,task_id,reviewer_id,status,comment)
 values(v_task.workspace_id,p_task,(select auth.uid()),case when p_approve then 'Validé' else 'Corrections demandées' end,left(p_comment,2000));
end $$;
revoke all on function public.review_studio_task(uuid,boolean,text) from public,anon;
grant execute on function public.review_studio_task(uuid,boolean,text) to authenticated;
-- Previously installed privileged lookup functions must not be callable anonymously.
revoke execute on function public.is_member(uuid) from public, anon;
revoke execute on function public.is_manager(uuid) from public, anon;
revoke execute on function public.is_admin(uuid) from public, anon;
revoke execute on function public.can_view_conversation(uuid) from public, anon;
revoke execute on function public.can_view_document(uuid) from public, anon;
revoke execute on function public.new_profile() from public, anon;
grant execute on function public.is_member(uuid),public.is_manager(uuid),public.is_admin(uuid),public.can_view_conversation(uuid),public.can_view_document(uuid) to authenticated;


-- Fix legacy Storage policies: previously compared documents.storage_path to documents.name,
-- not to storage.objects.name. No stored object is deleted by these policy updates.
drop policy if exists studio_storage_read on storage.objects;
create policy studio_storage_read on storage.objects for select to authenticated using(
 bucket_id='studio-private' and exists(
  select 1 from public.documents d where d.storage_path=storage.objects.name
  and public.can_view_document(d.id)));
drop policy if exists studio_storage_delete on storage.objects;
create policy studio_storage_delete on storage.objects for delete to authenticated using(
 bucket_id='studio-private' and exists(
  select 1 from public.documents d where d.storage_path=storage.objects.name
  and d.author_id=(select auth.uid()) and public.is_member(d.workspace_id)));
commit;
