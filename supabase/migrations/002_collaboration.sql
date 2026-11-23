-- MAHAVEL Studio 0.2.0: appliquer UNE SEULE FOIS après 001_initial.sql.
-- Migration additive : aucune suppression de données existantes.
-- IMPORTANT : tester les permissions avec deux comptes avant toute mise en production.
begin;

alter table public.profiles
  add column if not exists color text not null default '#82919f',
  add column if not exists avatar_url text,
  add column if not exists job_title text,
  add column if not exists contact_url text;
alter table public.profiles drop constraint if exists profiles_color_hex;
alter table public.profiles add constraint profiles_color_hex check(color ~ '^#[0-9A-Fa-f]{6}$');
update public.profiles set color='#D84848' where lower(display_name)='loan' and color='#82919f';
update public.profiles set color='#3C956A' where lower(display_name)='muriel' and color='#82919f';
update public.profiles set color='#C69B36' where lower(display_name)='nicolas' and color='#82919f';

alter table public.events add column if not exists responsible_id uuid references public.profiles(id);
alter table public.documents add column if not exists visibility text not null default 'workspace';
alter table public.documents drop constraint if exists documents_visibility_allowed;
alter table public.documents add constraint documents_visibility_allowed check(visibility in ('workspace','targeted'));
alter table public.messages add column if not exists document_id uuid references public.documents(id) on delete set null;

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key(conversation_id,user_id)
);
create table if not exists public.document_recipients (
  document_id uuid not null references public.documents(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(document_id,user_id)
);
create index if not exists document_recipients_by_user on public.document_recipients(user_id,document_id);
create index if not exists conversation_members_by_user on public.conversation_members(user_id,conversation_id);

-- Les conversations existantes de V0.1 restent générales et visibles à l'espace.
-- Les nouvelles conversations « Direct » et « Groupe » sont strictement privées.
update public.conversations set kind='Générale' where kind not in ('Direct','Groupe','Projet','Générale');
update public.conversations set kind='Générale' where kind='Groupe' and not exists
 (select 1 from public.conversation_members cm where cm.conversation_id=conversations.id);

create or replace function public.can_view_conversation(cid uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists (
    select 1 from public.conversations c
    where c.id=cid and public.is_member(c.workspace_id) and
    (c.kind not in ('Direct','Groupe') or exists
      (select 1 from public.conversation_members cm where cm.conversation_id=cid and cm.user_id=(select auth.uid())))
  )
$$;
create or replace function public.can_view_document(did uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists (
    select 1 from public.documents d where d.id=did
      and public.is_member(d.workspace_id)
      and (d.keep or d.expires_at>now())
      and (d.visibility='workspace' or d.author_id=(select auth.uid())
           or exists (select 1 from public.document_recipients r where r.document_id=d.id and r.user_id=(select auth.uid())))
  )
$$;

-- Restreindre la lecture initialement large de V0.1.
drop policy if exists read_conversations on public.conversations;
create policy read_conversations on public.conversations for select to authenticated
 using(public.can_view_conversation(id));
drop policy if exists read_messages on public.messages;
create policy read_messages on public.messages for select to authenticated
 using(expires_at>now() and public.can_view_conversation(conversation_id));
drop policy if exists message_insert on public.messages;
create policy message_insert on public.messages for insert to authenticated
 with check(author_id=(select auth.uid()) and public.is_member(workspace_id)
   and public.can_view_conversation(conversation_id)
   and exists(select 1 from public.conversations c where c.id=conversation_id and c.workspace_id=messages.workspace_id)
   and (document_id is null or public.can_view_document(document_id)));
create policy message_delete on public.messages for delete to authenticated
 using(author_id=(select auth.uid()) and public.can_view_conversation(conversation_id));
drop policy if exists read_documents on public.documents;
create policy read_documents on public.documents for select to authenticated
 using(public.can_view_document(id));
drop policy if exists doc_update on public.documents;
create policy doc_update on public.documents for update to authenticated
 using(author_id=(select auth.uid()) and public.is_member(workspace_id))
 with check(author_id=(select auth.uid()) and public.is_member(workspace_id) and storage_path like workspace_id::text||'/%');
drop policy if exists doc_delete on public.documents;
create policy doc_delete on public.documents for delete to authenticated
 using(author_id=(select auth.uid()) and public.is_member(workspace_id));

alter table public.conversation_members enable row level security;
alter table public.document_recipients enable row level security;
create policy cm_read on public.conversation_members for select to authenticated
 using(public.can_view_conversation(conversation_id));
create policy dr_read on public.document_recipients for select to authenticated
 using(public.can_view_document(document_id));
create policy dr_add on public.document_recipients for insert to authenticated
 with check(exists (select 1 from public.documents d where d.id=document_id
   and d.author_id=(select auth.uid()) and d.visibility='targeted'
   and public.is_member(d.workspace_id)
   and exists(select 1 from public.memberships m where m.workspace_id=d.workspace_id and m.user_id=document_recipients.user_id)));
create policy dr_delete on public.document_recipients for delete to authenticated
 using(exists(select 1 from public.documents d where d.id=document_id and d.author_id=(select auth.uid())));

-- Les informations de profil sont visibles uniquement entre membres d'un même espace.
-- Les détails sensibles (e-mail) ne sont pas stockés dans cette table.
drop policy if exists profile_select on public.profiles;
create policy profile_select on public.profiles for select to authenticated using(
 id=(select auth.uid()) or exists (
   select 1 from public.memberships m where m.user_id=profiles.id and public.is_member(m.workspace_id)
 ));

-- Définir l'auteur et les participants côté serveur, jamais à partir d'une identité JS.
create or replace function public.create_studio_conversation(
 p_workspace uuid,p_kind text,p_name text,p_participants uuid[])
returns uuid language plpgsql security definer set search_path='' as $$
declare cid uuid; other_count int;
begin
 if auth.uid() is null or not public.is_member(p_workspace) then raise exception 'Accès refusé';end if;
 if p_kind not in ('Direct','Groupe') then raise exception 'Type interdit';end if;
 select count(distinct x) into other_count from unnest(p_participants) x where x is not null and x<>auth.uid();
 if other_count=0 or (p_kind='Direct' and other_count<>1) then raise exception 'Destinataires incorrects';end if;
 if exists(select 1 from unnest(p_participants) x where x is not null and x<>auth.uid()
           and not exists(select 1 from public.memberships m where m.workspace_id=p_workspace and m.user_id=x))
 then raise exception 'Un destinataire ne fait pas partie de cet espace';end if;
 insert into public.conversations(workspace_id,name,kind,created_by)
 values(p_workspace,left(coalesce(nullif(trim(p_name),''),'Groupe'),120),p_kind,auth.uid()) returning id into cid;
 insert into public.conversation_members(conversation_id,user_id)
 select cid,x from (select auth.uid() x union select unnest(p_participants)) q where x is not null;
 return cid;
end $$;

create or replace function public.get_or_create_direct_conversation(p_workspace uuid,p_other uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare cid uuid;
begin
 if auth.uid() is null or p_other=auth.uid() or not public.is_member(p_workspace)
 or not exists(select 1 from public.memberships where workspace_id=p_workspace and user_id=p_other)
 then raise exception 'Destinataire non autorisé';end if;
 select c.id into cid from public.conversations c
 where c.workspace_id=p_workspace and c.kind='Direct'
 and (select count(*) from public.conversation_members cm where cm.conversation_id=c.id)=2
 and exists(select 1 from public.conversation_members cm where cm.conversation_id=c.id and cm.user_id=auth.uid())
 and exists(select 1 from public.conversation_members cm where cm.conversation_id=c.id and cm.user_id=p_other)
 limit 1;
 if cid is null then cid:=public.create_studio_conversation(p_workspace,'Direct','Privé',array[p_other]);end if;
 return cid;
end $$;
revoke all on function public.create_studio_conversation(uuid,text,text,uuid[]) from public,anon;
revoke all on function public.get_or_create_direct_conversation(uuid,uuid) from public,anon;
grant execute on function public.create_studio_conversation(uuid,text,text,uuid[]) to authenticated;
grant execute on function public.get_or_create_direct_conversation(uuid,uuid) to authenticated;
grant execute on function public.can_view_conversation(uuid) to authenticated;
grant execute on function public.can_view_document(uuid) to authenticated;

-- RLS du stockage : aucune lecture des fichiers ciblés par un membre non destinataire.
drop policy if exists studio_storage_read on storage.objects;
create policy studio_storage_read on storage.objects for select to authenticated
 using(bucket_id='studio-private' and exists(
   select 1 from public.documents d where d.storage_path=name and public.can_view_document(d.id)));
-- Autoriser la suppression des objets par auteur et vérifier les documents.
-- La suppression côté client est effectuée avant celle de la ligne documents.
drop policy if exists studio_storage_delete on storage.objects;
create policy studio_storage_delete on storage.objects for delete to authenticated
 using(bucket_id='studio-private' and exists(
   select 1 from public.documents d where d.storage_path=name and d.author_id=auth.uid() and public.is_member(d.workspace_id)));

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('studio-avatars','studio-avatars',false,2097152,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
create policy studio_avatar_read on storage.objects for select to authenticated
 using(bucket_id='studio-avatars' and public.is_member(split_part(name,'/',1)::uuid));
create policy studio_avatar_insert on storage.objects for insert to authenticated
 with check(bucket_id='studio-avatars' and split_part(name,'/',2)='avatars' and
 split_part(split_part(name,'/',3),'.',1)=auth.uid()::text and public.is_member(split_part(name,'/',1)::uuid));
create policy studio_avatar_update on storage.objects for update to authenticated
 using(bucket_id='studio-avatars' and split_part(split_part(name,'/',3),'.',1)=auth.uid()::text)
 with check(bucket_id='studio-avatars' and split_part(split_part(name,'/',3),'.',1)=auth.uid()::text);

grant select,insert,update,delete on public.messages to authenticated;
grant select,insert,update,delete on public.conversations to authenticated;
grant select,insert,delete on public.conversation_members to authenticated;
grant select,insert,delete on public.document_recipients to authenticated;
grant select,update on public.profiles to authenticated;
grant select,insert,update,delete on public.projects,public.tasks,public.events,public.availability,public.external_links to authenticated;
grant select,insert,update,delete on public.documents to authenticated;

-- Supprimer / modifier seulement lorsque les politiques l'autorisent.
create policy project_delete on public.projects for delete to authenticated using(created_by=auth.uid() or public.is_manager(workspace_id));
create policy task_delete on public.tasks for delete to authenticated using(created_by=auth.uid() or public.is_manager(workspace_id));
create policy event_delete on public.events for delete to authenticated using(created_by=auth.uid() or public.is_manager(workspace_id));
create policy avail_delete on public.availability for delete to authenticated using(user_id=auth.uid() or public.is_manager(workspace_id));
create policy convo_delete on public.conversations for delete to authenticated using(created_by=auth.uid() and public.can_view_conversation(id));
create policy link_delete on public.external_links for delete to authenticated using(author_id=auth.uid());
-- Les anciennes conversations générales restent lisibles par l'équipe.
-- Les futures opérations de migration doivent conserver cette distinction.
commit;
