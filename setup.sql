-- Revisionary cloud setup. Run once in Supabase: SQL Editor > New query > paste > Run.
-- Also: Authentication > Providers > Email > turn OFF "Confirm email" (or students must confirm before login).
create table profiles(id uuid primary key references auth.users on delete cascade, email text, name text, role text check (role in ('student','teacher')), school text);
create table classes(id uuid primary key default gen_random_uuid(), teacher_id uuid references profiles(id) on delete cascade, name text not null, code text unique not null, created_at timestamptz default now());
create table members(class_id uuid references classes(id) on delete cascade, student_id uuid references profiles(id) on delete cascade, primary key(class_id,student_id));
create table tasks(id uuid primary key default gen_random_uuid(), class_id uuid references classes(id) on delete cascade, question text not null, marks int default 6, created_at timestamptz default now());
create table submissions(id uuid primary key default gen_random_uuid(), task_id uuid references tasks(id) on delete cascade, student_id uuid references profiles(id) on delete cascade, answer text, mark int, feedback text, submitted_at timestamptz default now(), marked_at timestamptz, unique(task_id,student_id));
alter table profiles enable row level security; alter table classes enable row level security; alter table members enable row level security; alter table tasks enable row level security; alter table submissions enable row level security;
create function owns_class(cid uuid) returns boolean language sql security definer stable as $$ select exists(select 1 from classes where id=cid and teacher_id=auth.uid()) $$;
create function is_member(cid uuid) returns boolean language sql security definer stable as $$ select exists(select 1 from members where class_id=cid and student_id=auth.uid()) $$;
create function owns_task(tid uuid) returns boolean language sql security definer stable as $$ select exists(select 1 from tasks t join classes c on c.id=t.class_id where t.id=tid and c.teacher_id=auth.uid()) $$;
create function teaches(uid uuid) returns boolean language sql security definer stable as $$ select exists(select 1 from members m join classes c on c.id=m.class_id where m.student_id=uid and c.teacher_id=auth.uid()) $$;
create function join_class(c text) returns uuid language plpgsql security definer as $$ declare cid uuid; begin select id into cid from classes where code=upper(trim(c)); if cid is null then raise exception 'Class code not found'; end if; insert into members values(cid,auth.uid()) on conflict do nothing; return cid; end $$;
create policy p_sel on profiles for select using (id=auth.uid() or teaches(id));
create policy p_ins on profiles for insert with check (id=auth.uid());
create policy p_upd on profiles for update using (id=auth.uid());
create policy c_teacher on classes for all using (teacher_id=auth.uid()) with check (teacher_id=auth.uid());
create policy c_student on classes for select using (is_member(id));
create policy m_sel on members for select using (student_id=auth.uid() or owns_class(class_id));
create policy t_teacher on tasks for all using (owns_class(class_id)) with check (owns_class(class_id));
create policy t_student on tasks for select using (is_member(class_id));
create policy s_sel on submissions for select using (student_id=auth.uid() or owns_task(task_id));
create policy s_ins on submissions for insert with check (student_id=auth.uid() and mark is null and feedback is null);
create policy s_upd_student on submissions for update using (student_id=auth.uid() and mark is null) with check (student_id=auth.uid() and mark is null);
create policy s_upd_teacher on submissions for update using (owns_task(task_id)) with check (owns_task(task_id));
