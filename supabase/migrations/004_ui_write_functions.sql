-- =====================================================================
--  PG Rent App  |  004_ui_write_functions.sql
--  Two more doors for the screens (same rules as 002: check the caller
--  first, plain-English errors, explicit grant).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Add many rooms (each with beds A, B, C ...) in one all-or-nothing step.
--   p_first_room_number  first number, e.g. 101
--   p_room_count         how many rooms, 1 to 100
--   p_beds_per_room      1 to 12 (beds are labelled A to L)
--   p_prefix             optional text in front of every number, e.g. 'G' -> G101
-- Returns how many rooms were created. If any room number already exists
-- nothing is created and the message names the clash.
-- ---------------------------------------------------------------------
create or replace function rpc_add_rooms(
  p_pg_id              uuid,
  p_first_room_number  integer,
  p_room_count         integer,
  p_beds_per_room      integer,
  p_room_type_code     text     default null,
  p_floor              smallint default null,
  p_prefix             text     default ''
) returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_type    smallint;
  v_number  text;
  v_room    uuid;
  v_i       integer;
  v_b       integer;
begin
  if not is_pg_staff(p_pg_id, array['owner', 'manager']) then
    raise exception 'You do not have access to this PG' using errcode = '42501';
  end if;
  if p_room_count is null or p_room_count < 1 or p_room_count > 100 then
    raise exception 'Add between 1 and 100 rooms at a time';
  end if;
  if p_beds_per_room is null or p_beds_per_room < 1 or p_beds_per_room > 12 then
    raise exception 'Choose between 1 and 12 beds per room';
  end if;
  if p_first_room_number is null or p_first_room_number < 0 then
    raise exception 'Enter the first room number';
  end if;

  if p_room_type_code is not null then
    select id into v_type from room_types where code = p_room_type_code;
    if v_type is null then
      raise exception 'Unknown room type';
    end if;
  end if;

  for v_i in 0 .. p_room_count - 1 loop
    v_number := coalesce(p_prefix, '') || (p_first_room_number + v_i)::text;
    if exists (select 1 from rooms where pg_id = p_pg_id and room_number = v_number) then
      raise exception 'Room % already exists in this PG', v_number;
    end if;
    insert into rooms (pg_id, room_number, floor, room_type_id)
    values (p_pg_id, v_number, p_floor, v_type)
    returning id into v_room;
    for v_b in 1 .. p_beds_per_room loop
      insert into beds (room_id, label) values (v_room, chr(64 + v_b));
    end loop;
  end loop;

  return p_room_count;
end $$;


-- ---------------------------------------------------------------------
-- Fix the spelling of a guest's name BEFORE the guest has ever signed in.
-- Once the guest has signed in they manage their own name.
-- ---------------------------------------------------------------------
create or replace function rpc_correct_guest_name(p_person_id uuid, p_full_name text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_claimed boolean;
begin
  if coalesce(trim(p_full_name), '') = '' then
    raise exception 'Enter the guest''s name';
  end if;
  if not exists (select 1 from stays s
                 where s.person_id = p_person_id and s.status <> 'vacated'
                   and is_pg_staff(s.pg_id, array['owner', 'manager'])) then
    raise exception 'You do not have access to this guest' using errcode = '42501';
  end if;
  select auth_user_id is not null into v_claimed from persons where id = p_person_id;
  if v_claimed then
    raise exception 'This guest has signed in and manages their own name';
  end if;
  update persons set full_name = trim(p_full_name) where id = p_person_id;
end $$;

grant execute on function
  rpc_add_rooms(uuid, integer, integer, integer, text, smallint, text),
  rpc_correct_guest_name(uuid, text)
to authenticated;
