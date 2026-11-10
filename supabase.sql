-- 마이오프 교대달력: 개인 코드 동기화용 테이블 (Supabase SQL Editor에서 한 번 실행)
create table if not exists public.calendars (
  code text primary key check (code ~ '^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$'),
  data jsonb not null,
  updated_at timestamptz not null default now()
);
-- RLS on, no policies: nobody can list or read the table directly.
alter table public.calendars enable row level security;

-- Only these two functions are exposed; you must know a code to read or write it.
create or replace function public.get_calendar(p_code text) returns jsonb
language sql security definer set search_path = public as $$
  select data from calendars where code = p_code
$$;

create or replace function public.save_calendar(p_code text, p_data jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  if octet_length(p_data::text) > 500000 then raise exception 'calendar too large'; end if;
  insert into calendars(code, data, updated_at) values (p_code, p_data, now())
  on conflict (code) do update set data = excluded.data, updated_at = now();
end $$;

revoke all on function public.get_calendar(text) from public;
revoke all on function public.save_calendar(text, jsonb) from public;
grant execute on function public.get_calendar(text) to anon;
grant execute on function public.save_calendar(text, jsonb) to anon;
