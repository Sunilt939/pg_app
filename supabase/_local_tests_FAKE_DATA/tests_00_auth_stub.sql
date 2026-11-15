-- TEST-ONLY (plain PostgreSQL): imitates the parts of Supabase that the migrations rely on.
-- Do NOT run this on a real Supabase project; it already has these.
-- SAFETY: this file creates FAKE people, phone numbers and logins.
-- It refuses to run unless psql is started with:  PGOPTIONS="-c app.allow_fake_data=yes"
-- NEVER run it on your Supabase project (dev or real). Scratch PostgreSQL on your own computer only.
\set ON_ERROR_STOP on
do $$
begin
  if coalesce(current_setting('app.allow_fake_data', true), '') <> 'yes' then
    raise exception 'STOP: this file creates FAKE people and logins. Run it only on a scratch PostgreSQL on your own computer, never on a Supabase project.';
  end if;
end $$;
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create table auth.users (id uuid primary key default gen_random_uuid(), phone text, email text);
create function auth.uid() returns uuid language sql stable as
$$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to anon, authenticated;
grant usage on schema public to anon, authenticated, service_role;
