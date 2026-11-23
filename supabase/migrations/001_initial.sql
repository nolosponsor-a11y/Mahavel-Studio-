-- MAHAVEL STUDIO / 001 / Exécuter dans Supabase SQL Editor sur un projet neuf
create extension if not exists pgcrypto;
create table public.profiles (id uuid primary key references auth.users(id) on delete cascade, display_name text not null default 'Collaborateur', created_at timestamptz not null default now());
create or replace function public.new_profile() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,display_name) values(new.id,coalesce(nullif(split_part(new.email,'@',1),''),'Collaborateur')) on conflict do nothing; return new;end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.new_profile();
insert into public.profiles(id,display_name) select id,coalesce(split_part(email,'@',1),'Collaborateur') from auth.users on conflict do nothing;
create table public.workspaces(id uuid primary key default gen_random_uuid(),name text not null,created_at timestamptz not null default now());
create table public.memberships(workspace_id uuid not null references public.workspaces(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,role text not null check(role in('admin','manager','member')),created_at timestamptz not null default now(),primary key(workspace_id,user_id));
create or replace function public.is_member(w uuid) returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.memberships where workspace_id=w and user_id=(select auth.uid()))$$;
create or replace function public.is_manager(w uuid) returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.memberships where workspace_id=w and user_id=(select auth.uid()) and role in('admin','manager'))$$;
create or replace function public.is_admin(w uuid) returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.memberships where workspace_id=w and user_id=(select auth.uid()) and role='admin')$$;
create table public.projects(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),name text not null,description text,category text default 'Vidéo',status text default 'Préparation',created_by uuid references public.profiles(id),created_at timestamptz default now(),updated_at timestamptz default now());
create table public.tasks(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),project_id uuid references public.projects(id) on delete set null,title text not null,description text,assignee_id uuid references public.profiles(id),created_by uuid references public.profiles(id),priority text default 'Normale',status text default 'À faire',due_at date,created_at timestamptz default now(),updated_at timestamptz default now());
create table public.events(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),project_id uuid references public.projects(id) on delete set null,title text not null,description text,category text default 'Autre',location text,starts_at timestamptz not null,ends_at timestamptz not null,created_by uuid references public.profiles(id),created_at timestamptz default now(),updated_at timestamptz default now(),constraint valid_event check (ends_at>starts_at));
create table public.availability(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),user_id uuid not null references public.profiles(id),label text not null,kind text not null default 'Indisponible',starts_at timestamptz not null,ends_at timestamptz not null,created_at timestamptz default now(),updated_at timestamptz default now(),check(ends_at>starts_at));
create table public.conversations(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),name text not null,kind text not null default 'Groupe',created_by uuid references public.profiles(id),created_at timestamptz default now(),updated_at timestamptz default now());
create table public.messages(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),conversation_id uuid not null references public.conversations(id) on delete cascade,author_id uuid not null references public.profiles(id),body text not null check(length(body)<=4000),created_at timestamptz default now(),expires_at timestamptz not null default (now() + interval '7 days'));
create table public.documents(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),name text not null,storage_path text not null unique,mime_type text,size_bytes bigint not null check(size_bytes>=0),author_id uuid not null references public.profiles(id),keep boolean not null default false,created_at timestamptz default now(),updated_at timestamptz default now(),expires_at timestamptz not null default (now() + interval '6 days'));
create table public.external_links(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),title text not null,url text not null check(url~'^https://'),author_id uuid references public.profiles(id),created_at timestamptz default now(),updated_at timestamptz default now());
create table public.approvals(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),task_id uuid references public.tasks(id) on delete cascade,reviewer_id uuid references public.profiles(id),status text not null default 'À valider',comment text,created_at timestamptz default now(),updated_at timestamptz default now());
create table public.notifications(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references public.workspaces(id),user_id uuid not null references public.profiles(id),title text not null,body text,read_at timestamptz,created_at timestamptz default now());
create table public.audit_log(id bigint generated always as identity primary key,workspace_id uuid not null references public.workspaces(id),actor_id uuid references public.profiles(id),action text not null,details jsonb default '{}'::jsonb,created_at timestamptz default now());
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$begin new.updated_at=now();return new;end$$;
do $$declare t text;begin foreach t in array array['projects','tasks','events','availability','conversations','documents','external_links','approvals'] loop execute format('create trigger trg_touch before update on public.%I for each row execute function public.touch_updated_at()',t);end loop;end$$;
-- Dates d'expiration imposées par le serveur, non modifiables par les clients.
create or replace function public.expiry_immutable() returns trigger language plpgsql as $$begin
 if tg_op='INSERT' then new.created_at=now(); new.expires_at=now()+case when tg_table_name='messages' then interval '7 days' else interval '6 days' end;
 else new.created_at=old.created_at;new.expires_at=old.expires_at;end if;
 return new;end$$;
create trigger message_expiry before insert or update on public.messages for each row execute function public.expiry_immutable();
create trigger document_expiry before insert or update on public.documents for each row execute function public.expiry_immutable();
-- RLS, accès conditionné à l'espace ; opération lecture refusée aux autres membres
alter table public.profiles enable row level security;
create policy profile_select on public.profiles for select to authenticated using(id=(select auth.uid()) or exists(select 1 from public.memberships me join public.memberships them on them.workspace_id=me.workspace_id where me.user_id=(select auth.uid()) and them.user_id=profiles.id));
create policy profile_update on public.profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
alter table public.workspaces enable row level security;
create policy workspace_read on public.workspaces for select to authenticated using(public.is_member(id));
alter table public.memberships enable row level security;
create policy membership_read on public.memberships for select to authenticated using(public.is_member(workspace_id));
create policy membership_insert on public.memberships for insert to authenticated with check(public.is_admin(workspace_id));
create policy membership_update on public.memberships for update to authenticated using(public.is_admin(workspace_id)) with check(public.is_admin(workspace_id));
create policy membership_delete on public.memberships for delete to authenticated using(public.is_admin(workspace_id));
do $$declare t text;begin foreach t in array array['projects','tasks','events','availability','conversations','messages','documents','external_links','approvals','notifications','audit_log'] loop execute format('alter table public.%I enable row level security',t);if t='messages' or t='documents' then execute format('create policy %I on public.%I for select to authenticated using(public.is_member(workspace_id) and (expires_at>now() or %s))','read_'||t,t,case when t='documents' then 'keep' else 'false' end); else execute format('create policy %I on public.%I for select to authenticated using(public.is_member(workspace_id))','read_'||t,t); end if;end loop;end $$;
create policy project_insert on public.projects for insert to authenticated with check(public.is_member(workspace_id) and created_by=(select auth.uid()));
create policy project_update on public.projects for update to authenticated using(public.is_manager(workspace_id) or created_by=(select auth.uid())) with check(public.is_member(workspace_id));
create policy task_insert on public.tasks for insert to authenticated with check(public.is_member(workspace_id) and created_by=(select auth.uid()));
create policy task_update on public.tasks for update to authenticated using(public.is_manager(workspace_id) or created_by=(select auth.uid()) or assignee_id=(select auth.uid())) with check(public.is_member(workspace_id));
create policy event_insert on public.events for insert to authenticated with check(public.is_member(workspace_id) and created_by=(select auth.uid()));
create policy event_update on public.events for update to authenticated using(public.is_manager(workspace_id) or created_by=(select auth.uid())) with check(public.is_member(workspace_id));
create policy avail_insert on public.availability for insert to authenticated with check(public.is_member(workspace_id) and user_id=(select auth.uid()));
create policy avail_update on public.availability for update to authenticated using(user_id=(select auth.uid()) or public.is_manager(workspace_id)) with check(public.is_member(workspace_id));
create policy convo_insert on public.conversations for insert to authenticated with check(public.is_member(workspace_id) and created_by=(select auth.uid()));
create policy message_insert on public.messages for insert to authenticated with check(public.is_member(workspace_id) and author_id=(select auth.uid()) and exists(select 1 from public.conversations c where c.id=conversation_id and c.workspace_id=messages.workspace_id));
create policy doc_insert on public.documents for insert to authenticated with check(public.is_member(workspace_id) and author_id=(select auth.uid()) and storage_path like workspace_id::text||'/%');
create policy doc_update on public.documents for update to authenticated using(public.is_manager(workspace_id) or author_id=(select auth.uid())) with check(public.is_member(workspace_id) and storage_path like workspace_id::text||'/%');
create policy doc_delete on public.documents for delete to authenticated using(public.is_manager(workspace_id) or author_id=(select auth.uid()));
create policy links_insert on public.external_links for insert to authenticated with check(public.is_member(workspace_id) and author_id=(select auth.uid()));
create policy approval_insert on public.approvals for insert to authenticated with check(public.is_manager(workspace_id) and reviewer_id=(select auth.uid()));
create policy approval_update on public.approvals for update to authenticated using(public.is_manager(workspace_id)) with check(public.is_manager(workspace_id));
create policy notif_update on public.notifications for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
-- Interdire le déplacement inter-espace via update en fixant le workspace_id.
create or replace function public.prevent_workspace_move() returns trigger language plpgsql as $$begin if new.workspace_id is distinct from old.workspace_id then raise exception 'Changement d’espace interdit';end if;return new;end$$;
do $$declare t text;begin foreach t in array array['projects','tasks','events','availability','conversations','documents','external_links','approvals'] loop execute format('create trigger no_workspace_move before update on public.%I for each row execute function public.prevent_workspace_move()',t);end loop;end$$;
-- Vérifier que les références de projets et tâches restent au sein du même espace.
create or replace function public.check_project_scope() returns trigger language plpgsql as $$begin if new.project_id is not null and not exists(select 1 from public.projects p where p.id=new.project_id and p.workspace_id=new.workspace_id) then raise exception 'Projet hors espace';end if;return new;end$$;
create trigger task_project_scope before insert or update on public.tasks for each row execute function public.check_project_scope();
create trigger event_project_scope before insert or update on public.events for each row execute function public.check_project_scope();
create or replace function public.check_approval_scope() returns trigger language plpgsql as $$begin if not exists(select 1 from public.tasks t where t.id=new.task_id and t.workspace_id=new.workspace_id) then raise exception 'Tâche hors espace';end if;return new;end$$;
create trigger approval_scope before insert or update on public.approvals for each row execute function public.check_approval_scope();
create index tasks_by_workspace on public.tasks(workspace_id,created_at desc);create index events_by_workspace on public.events(workspace_id,starts_at);create index messages_by_conversation on public.messages(conversation_id,created_at desc);create index documents_by_expiry on public.documents(expires_at) where keep=false;create index members_by_user on public.memberships(user_id);
-- Bucket privé et contrôle sur chemin workspace/uuid/nom.
insert into storage.buckets(id,name,public,file_size_limit) values('studio-private','studio-private',false,10485760) on conflict(id) do nothing;
create policy studio_storage_read on storage.objects for select to authenticated using(bucket_id='studio-private' and public.is_member(split_part(name,'/',1)::uuid));
create policy studio_storage_insert on storage.objects for insert to authenticated with check(bucket_id='studio-private' and public.is_member(split_part(name,'/',1)::uuid));
create policy studio_storage_delete on storage.objects for delete to authenticated using(bucket_id='studio-private' and exists(select 1 from public.documents d where d.storage_path=name and (d.author_id=(select auth.uid()) or public.is_manager(d.workspace_id))));
-- Realtime : notifications Postgres Changes filtrées par RLS
alter publication supabase_realtime add table public.tasks,public.events,public.projects,public.conversations,public.messages,public.documents,public.external_links,public.availability,public.notifications,public.approvals;
-- Nettoyage réel des messages (indépendant du navigateur)
create extension if not exists pg_cron;
select cron.schedule('mahavel-expire-messages','*/15 * * * *',$$delete from public.messages where created_at<now()-interval '7 days'$$);
-- Les fichiers sont supprimés via Edge Function : voir README et fonction cleanup-files.
