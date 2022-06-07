drop table if exists excuses cascade;

drop table if exists bell_schedule_history cascade;

drop table if exists groups_history cascade;

drop table if exists employees_history cascade;

drop table if exists posts cascade;

drop table if exists type_weights_history cascade;

drop table if exists marks cascade;

drop table if exists mark_types cascade;

drop table if exists quarters cascade;

drop table if exists holidays cascade;

drop table if exists salary_history cascade;

drop table if exists class_history cascade;

drop table if exists class_teacher_history cascade;

drop table if exists classes cascade;

drop table if exists journal cascade;

drop table if exists pupils cascade;

drop table if exists groups_to_events cascade;

drop table if exists events cascade;

drop table if exists themes cascade;

drop table if exists groups_to_schedule cascade;

drop table if exists groups cascade;

drop table if exists schedule_history cascade;

drop type if exists week_day cascade;

drop table if exists rooms cascade;

drop table if exists subjects cascade;

drop table if exists employees cascade;

drop function if exists get_week_day(date) cascade;

drop function if exists has_post(integer, integer, timestamp) cascade;

drop function if exists add_post(integer, integer) cascade;

drop function if exists delete_post(integer, integer) cascade;

drop function if exists study_start(integer) cascade;

drop function if exists work_start(integer) cascade;

drop function if exists bell_begin_time(date, integer) cascade;

drop function if exists bell_end_time(date, integer) cascade;

drop function if exists was_at_lecture(integer, integer) cascade;

drop function if exists is_studying(integer, timestamp) cascade;

drop function if exists is_working(integer, timestamp) cascade;

drop function if exists get_bells_schedule(date) cascade;

drop function if exists get_quarter_begin(date) cascade;

drop function if exists get_quarter_end(date) cascade;

drop function if exists get_parity(date) cascade;

drop function if exists get_schedule(date) cascade;

drop function if exists add_bell(integer, time, time, timestamp) cascade;

drop function if exists get_schedule(week_day, boolean, date) cascade;

drop function if exists add_to_schedule(integer, integer, integer, week_day, boolean, timestamp) cascade;

drop function if exists get_pupils_from_group(integer, timestamp) cascade;

drop function if exists get_groups_from_event(integer) cascade;

drop function if exists get_groups_of_pupil(integer, timestamp) cascade;

drop function if exists delete_from_group(integer, integer, timestamp) cascade;

drop function if exists bell_schedule_history_insert_trigger() cascade;

drop function if exists schedule_history_insert_trigger() cascade;

drop function if exists quarters_insert_trigger() cascade;

drop function if exists holidays_insert_trigger() cascade;

drop function if exists journal_insert_trigger() cascade;

drop function if exists groups_to_events_delete_trigger() cascade;

