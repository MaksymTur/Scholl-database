--type block

CREATE TYPE week_day AS enum ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

--type block end
--table block

CREATE TABLE rooms
(
    title     text    NOT NULL,
    room_type text    NOT NULL,
    seats     integer NOT NULL,
    room_id   serial PRIMARY KEY,

    UNIQUE (title)
);

CREATE TABLE subjects
(
    title      text NOT NULL,
    subject_id serial PRIMARY KEY
);

CREATE TABLE pupils
(
    date_of_birth date        NOT NULL,
    first_name    varchar(20) NOT NULL,
    second_name   varchar(20) NOT NULL,
    pupil_id      serial PRIMARY KEY
);


CREATE TABLE themes
(
    title          text                    NOT NULL,
    subject_id     int REFERENCES subjects NOT NULL,
    lessons_length integer                 NOT NULL,
    theme_order    integer                 NOT NULL,

    theme_id       serial PRIMARY KEY,

    UNIQUE (title, subject_id),
    UNIQUE (subject_id, theme_order)
);

CREATE TABLE excuses
(
    pupil_id   int REFERENCES pupils NOT NULL,
    reason     text,
    begin_date date                  NOT NULL,
    begin_bell int,
    end_date   date                  NOT NULL,
    end_bell   int
);

CREATE TABLE bell_schedule_history
(
    bell_order  int,
    begin_time  time               NOT NULL,
    end_time    time               NOT NULL,
    change_time date DEFAULT now() NOT NULL
);

CREATE TABLE "groups"
(
    title      text                        NOT NULL,
    subject_id integer REFERENCES subjects NOT NULL,
    group_id   serial PRIMARY KEY
);

CREATE TABLE groups_history
(
    pupil_id      int REFERENCES pupils   NOT NULL,
    group_id      int REFERENCES "groups" NOT NULL,
    add_time      timestamp DEFAULT now() NOT NULL,
    deletion_time timestamp DEFAULT NULL,

    PRIMARY KEY (pupil_id, group_id, add_time)
);

CREATE TABLE workers
(
    first_name  text,
    second_name text,
    worker_id   serial PRIMARY KEY
);

CREATE TABLE posts
(
    title   text,
    post_id serial PRIMARY KEY
);


CREATE TABLE workers_history
(
    worker_id     int REFERENCES workers NOT NULL,
    post_id       int REFERENCES posts   NOT NULL,
    add_time      timestamp              NOT NULL,
    deletion_time timestamp DEFAULT NULL,

    PRIMARY KEY (worker_id, post_id, add_time)
);


-- CREATE FUNCTION get_lesson_bounds(lesson_date date, lesson_bell int)
--     RETURNS record AS
-- $$
-- declare
--     res record;
-- begin
--     SELECT begin_time, end_time
--     FROM bell_schedule_history
--     WHERE bell_order = lesson_bell
--       AND change_time = (SELECT MAX(change_time)
--                          FROM bell_schedule_history
--                          WHERE bell_order = lesson_bell
--                            AND change_time <= lesson_date)
--     INTO res;
--     return res;
-- end;
-- $$ language plpgsql;

CREATE TABLE schedule_history
(
    teacher_id  integer REFERENCES workers NOT NULL,
    room_id     integer REFERENCES rooms,
    bell_number integer,
    "week_day"  week_day                   NOT NULL,
    is_odd_week bool,
    change_time timestamp DEFAULT now()    NOT NULL,
    id          serial PRIMARY KEY,

    UNIQUE (teacher_id, room_id, bell_number, "week_day", is_odd_week, change_time)
);

CREATE TABLE events
(
    room_id    integer REFERENCES rooms,
    teacher_id integer REFERENCES workers NOT NULL,
    theme_id   integer REFERENCES themes,
    event_date date                       NOT NULL,
    event_bell int                        NOT NULL,
    event_id   serial PRIMARY KEY,

    UNIQUE (teacher_id, event_date, event_bell)
);

CREATE TABLE mark_types
(
    type_name varchar(10) NOT NULL,
    type_id   integer PRIMARY KEY
);

CREATE TABLE type_weights_history
(
    type_id     integer REFERENCES mark_types NOT NULL,
    change_date date                          NOT NULL,
    weight      NUMERIC(5, 2)
);

CREATE TABLE marks
(
    pupil_id integer REFERENCES pupils     NOT NULL,
    event_id integer REFERENCES events     NOT NULL,
    mark     integer                       NOT NULL,
    type_id  integer REFERENCES mark_types NOT NULL,

    PRIMARY KEY (pupil_id, event_id, mark)
);

CREATE TABLE quarters
(
    begin_date date NOT NULL,
    end_date   date NOT NULL,

    PRIMARY KEY (begin_date, end_date)
);

CREATE TABLE holidays
(
    begin_date date NOT NULL,
    end_date   date NOT NULL,

    PRIMARY KEY (begin_date, end_date)
);

CREATE TABLE salary_history
(
    worker_id   int REFERENCES workers NOT NULL,
    salary      int                    NOT NULL,
    change_time timestamp              NOT NULL,

    PRIMARY KEY (worker_id, change_time)
);

CREATE TABLE classes
(
    title      varchar(10) NOT NULL,
    study_year int         NOT NULL,
    class_id   serial PRIMARY KEY
);

CREATE TABLE class_history
(
    pupil_id      int REFERENCES pupils  NOT NULL,
    class_id      int REFERENCES classes NOT NULL,
    add_time      timestamp              NOT NULL,
    deletion_time timestamp DEFAULT NULL,

    PRIMARY KEY (pupil_id, class_id, add_time)
);

CREATE TABLE class_teacher_history
(
    class_id    int REFERENCES classes NOT NULL,
    teacher_id  int REFERENCES workers NOT NULL,
    change_time timestamp              NOT NULL,

    PRIMARY KEY (class_id, teacher_id, change_time)
);

CREATE TABLE journal
(
    pupil_id int REFERENCES pupils NOT NULL,
    event_id int REFERENCES events NOT NULL,

    PRIMARY KEY (pupil_id, event_id)
);

CREATE TABLE groups_to_events
(
    "group" int REFERENCES groups NOT NULL,
    event   int REFERENCES events NOT NULL,

    PRIMARY KEY ("group", event)
);

CREATE TABLE groups_to_schedule
(
    "group"           int REFERENCES groups           NOT NULL,
    event_in_schedule int REFERENCES schedule_history NOT NULL,

    PRIMARY KEY ("group", event_in_schedule)
);

--table block end
-- functions block

CREATE FUNCTION has_post(worker int, post int, check_time timestamp DEFAULT now())
    RETURNS bool AS
$$
begin
    return (SELECT COUNT(*)
            FROM workers_history
            WHERE worker_id = worker
              AND post_id = post
              AND add_time <= check_time
              AND (deletion_time IS NULL OR deletion_time > check_time)) = 1;
end;
$$ language plpgsql;

CREATE FUNCTION add_post(worker int, post int)
    RETURNS bool AS
$$
begin
    if has_post(worker, post) then
        return false;
    end if;
    INSERT INTO workers_history(worker_id, post_id, add_time)
    VALUES (worker, post, now());
    return true;
end
$$ language plpgsql;

CREATE FUNCTION delete_post(worker int, post int)
    RETURNS bool AS
$$
begin
    if not has_post(worker, post) then
        return false;
    end if;
    UPDATE workers_history
    SET deletion_time = now()
    WHERE deletion_time IS NULL;
    return true;
end
$$ language plpgsql;

CREATE FUNCTION study_start(pupil_id int)
    RETURNS timestamp AS
$$
begin
    SELECT add_time
    FROM class_history
    WHERE class_history.pupil_id = study_start.pupil_id
    ORDER BY 1
    LIMIT 1;
end
$$ language plpgsql;

CREATE OR REPLACE FUNCTION bell_begin_time(bell_date date, bell_order int)
    RETURNS timestamp AS
$$
begin
    if (bell_order IS NULL) then
        return bell_date;
    end if;
    SELECT begin_time
    FROM bell_schedule_history
    WHERE change_time < bell_date
      AND bell_schedule_history.bell_order = bell_begin_time.bell_order
    ORDER BY change_time DESC
    LIMIT 1;
end
$$ language plpgsql;

CREATE FUNCTION bell_end_time(bell_date date, bell_order int)
    RETURNS timestamp AS
$$
begin
    SELECT end_time
    FROM bell_schedule_history
    WHERE change_time < bell_date
      AND bell_schedule_history.bell_order = bell_end_time.bell_order
    ORDER BY change_time DESC
    LIMIT 1;
end
$$ language plpgsql;

CREATE FUNCTION was_at_lecture(pupil_id int, event_id int)
    RETURNS boolean AS
$$
begin
    return EXISTS((SELECT journal.pupil_id
                   FROM journal
                   WHERE journal.pupil_id = was_at_lecture.pupil_id
                     AND journal.event_id = was_at_lecture.event_id));
end
$$ language plpgsql;

--functions block end
--checkers and triggers block

ALTER TABLE rooms
    ADD CONSTRAINT rooms_seats_check
        CHECK (
            seats >= 0
            );

ALTER TABLE themes
    ADD CONSTRAINT themes_length_check
        CHECK (
            lessons_length > 0
            );

ALTER TABLE excuses
    ADD CONSTRAINT excuses_check
        CHECK (
                    begin_date < end_date OR (begin_date = end_date AND excuses.begin_bell < end_bell)
            );

ALTER TABLE excuses
    ADD CONSTRAINT excuses_length_check
        CHECK (
                    begin_date < end_date OR (begin_date = end_date AND excuses.begin_bell < end_bell)
            );

ALTER TABLE excuses
    ADD CONSTRAINT excuses_begin_bell_exists_check
        CHECK (
            bell_begin_time(begin_date, begin_bell) IS NOT NULL
            );

ALTER TABLE excuses
    ADD CONSTRAINT excuses_begin_after_study_begin_check
        CHECK (
            bell_begin_time(begin_date, begin_bell) >= study_start(pupil_id)
            );

ALTER TABLE bell_schedule_history
    ADD CONSTRAINT bell_schedule_history_normal_length_check
        CHECK (
            begin_time < end_time
            );

ALTER TABLE groups_history
    ADD CONSTRAINT groups_history_add_before_deletion_check
        CHECK (
            add_time < deletion_time
            );

ALTER TABLE workers_history
    ADD CONSTRAINT workers_history_add_before_deletion_check
        CHECK (
            add_time < deletion_time
            );

ALTER TABLE events
    ADD CONSTRAINT events_bell_exists_check
        CHECK (
            bell_begin_time(event_date, event_bell) IS NOT NULL
            );

CREATE OR REPLACE FUNCTION events_insert_trigger()
    RETURNS TRIGGER AS
$$
begin
    if (!EXISTS(SELECT *
                FROM events
                WHERE events.room_id = NEW.room_id
                  AND events.event_date = NEW.event_date
                  AND events.event_bell = NEW.event_bell) AND
        !EXISTS(SELECT *
                FROM events
                WHERE events.teacher_id = NEW.teacher_id
                  AND events.event_date = NEW.event_date
                  AND events.event_bell = NEW.event_bell)) then
        return NEW;
    else
        return NULL;
    end if;
end;
$$
    LANGUAGE PLPGSQL;

CREATE TRIGGER events_insert_trigger
    BEFORE INSERT
    ON events
    FOR EACH ROW
EXECUTE PROCEDURE events_insert_trigger();

ALTER TABLE marks
    ADD CONSTRAINT marks_pupil_was_at_lecture_check
        CHECK (
            was_at_lecture(pupil_id, event_id)
            );

ALTER TABLE marks
    ADD CONSTRAINT marks_in_boundaries
        CHECK (
            mark >= 1 AND mark <= 12
            );

ALTER TABLE quarters
    ADD CONSTRAINT quarters_begin_before_end
        CHECK (
            begin_date < end_date
            );

ALTER TABLE holidays
    ADD CONSTRAINT holidays_begin_before_end
        CHECK (
            begin_date < end_date
            );

ALTER TABLE classes
    ADD CONSTRAINT classes_normal_study_year_check
        CHECK (
            study_year > 0 AND study_year < 13
            );

--checkers and triggers block end
--data examples block

insert into rooms (title, room_type, seats)
values ('101a', 'gym', 40),
       ('102a', 'basic', 8),
       ('102b', 'basic', 8),
       ('102c', 'basic', 8);
-- select * from rooms;

insert into subjects (title)
values ('Mathematics'),
       ('English');
--  select * from subjects;

insert into pupils (date_of_birth, first_name, second_name)
values ('2015-01-23', 'Ernie', 'Webber'),
       ('2015-02-15', 'Ismail', 'Ferrell'),
       ('2015-04-25', 'Salahuddin', 'Fellows'),
       ('2015-05-04', 'Corban', 'Hirst'),
       ('2015-05-10', 'Fraya', 'Greene'),
       ('2015-05-15', 'Ida', 'Robins'),
       ('2015-05-21', 'Timur', 'Blackwell'),
       ('2015-07-23', 'Ellise', 'Knox');
-- select * from pupils;

insert into themes (title, subject_id, lessons_length, theme_order)
values ('Addition', 1, 20, 1),
       ('Subtraction', 1, 20, 2),
       ('Alphabet', 2, 10, 1),
       ('Words', 2, 30, 2);
-- select * from themes;

insert into bell_schedule_history (bell_order, begin_time, end_time)
values (1, '08:00', '08:45'),
       (2, '09:00', '09:45'),
       (3, '09:55', '10:40'),
       (4, '10:55', '11:40'),
       (5, '12:00', '12:45'),
       (6, '13:05', '13:50');
--  select * from bell_shedule_history;

insert into groups (title, subject_id)
values ('A1 Math group', 1),
       ('A1 English first group', 2),
       ('A1 English second group', 2),
       ('B1 English', 2);
--  select * from groups;

--data bug!!!
/*
insert into excuses (pupil_id, reason, begin_date, begin_bell, end_date, end_bell)
values (1, 'illness', '2015-05-27', 1, '2015-05-27', 6);
--  select * from excuses;
*/

insert into groups_history (pupil_id, group_id)
values (1, 1),
       (1, 2),
       (2, 1),
       (2, 2),
       (3, 1),
       (3, 2),
       (4, 1),
       (4, 2),
       (5, 1),
       (5, 3),
       (6, 1),
       (6, 3),
       (7, 1),
       (7, 3),
       (8, 4);
--  select * from groups_history;

insert into workers (first_name, second_name)
values ('Maksym', 'Tur'),
       ('Andrii', 'Kovryhin'),
       ('Aliaksandr', 'Skvarniuk');
--  select * from workers;

insert into posts (title)
values ('Director'),
       ('Head teacher'),
       ('Accountant'),
       ('classroom teacher');
--  select * from posts;

insert into workers_history (worker_id, post_id, add_time, deletion_time)
values (1, 3, '2021-08-09 07:00:00', default),
       (2, 1, '2021-08-09 07:01:00', default),
       (3, 2, '2021-08-09 07:02:00', '2021-08-15 07:02:00'),
       (3, 2, '2021-08-15 07:02:00', default),
       (3, 2, '2021-08-22 07:02:00', default),
       (2, 4, '2021-08-31 15:00:00', default),
       (3, 4, '2021-08-31 15:00:00', default);
--  select * from workers_history;

insert into schedule_history (teacher_id, room_id, bell_number, week_day, is_odd_week)
values (2, 2, 1, 'Thursday', True),
       (2, 2, 1, 'Thursday', False),
       (1, 4, 1, 'Thursday', False),
       (3, 2, 2, 'Thursday', True),
       (2, 3, 2, 'Thursday', True);
--  select * from schedule_history;

--data bug!!!
/*
insert into events (room_id, teacher_id, theme_id, event_date, event_bell)
values (3, 2, 1, '2015-05-27', 1),
       (2, 3, 3, '2015-05-27', 2),
       (3, 1, 3, '2015-05-27', 2);
--  select * from events;
 */

insert into mark_types(type_name, type_id)
values ('exam', 1),
       ('report', 2),
       ('activity', 3);

--data bug(violates check constraint "marks_pupil_was_at_lecture_check")
/*
insert into marks (pupil_id, event_id, mark, type_id)
values (2, 1, 10, 1),
       (2, 2, 2, 2),
       (3, 1, 4, 3),
       (3, 2, 9, 2),
       (4, 1, 5, 1),
       (4, 2, 8, 3),
       (5, 1, 7, 2),
       (5, 3, 10, 1),
       (6, 1, 9, 1),
       (6, 3, 6, 2),
       (7, 1, 10, 3),
       (7, 3, 5, 1);
--    select * from marks;
 */

insert into holidays (begin_date, end_date)
values ('2021-10-31', '2021-11-07'),
       ('2021-12-25', '2022-01-09'),
       ('2022-04-27', '2022-05-3'),
       ('2022-06-01', '2022-08-31');
-- select * from holidays;

insert into quarters (begin_date, end_date)
values ('2021-09-01', '2021-10-30'),
       ('2021-11-08', '2021-12-24'),
       ('2022-01-10', '2022-04-26'),
       ('2022-04-04', '2022-05-31');
--  select * from quarters;

insert into salary_history (worker_id, salary, change_time)
values (1, 35, '2021-08-31 12:00:00'),
       (2, 25, '2021-08-31 12:00:00'),
       (3, 20, '2021-08-31 12:00:00');
--  select * from salary_history;

insert into classes (title, study_year)
values ('A', 1),
       ('B', 1);
--  select * from classes;

insert into class_history (pupil_id, class_id, add_time)
values (1, 1, '2021-08-31 07:02:00'),
       (2, 1, '2021-08-31 07:02:00'),
       (3, 1, '2021-08-31 07:02:00'),
       (4, 1, '2021-08-31 07:02:00'),
       (5, 1, '2021-08-31 07:02:00'),
       (6, 1, '2021-08-31 07:02:01'),
       (7, 1, '2021-08-31 07:02:01'),
       (8, 2, '2021-08-31 07:02:01');
-- select * from class_history;

insert into class_teacher_history (class_id, teacher_id, change_time)
values (1, 2, '2021-08-31 09:00:00'),
       (2, 3, '2021-08-31 09:00:00');
-- select * from class_teacher_history;

--data bug(violates foreign key constraint "journal_event_id_fkey")
/*
insert into journal (pupil_id, event_id)
values (2, 1),
       (2, 2),
       (3, 1),
       (3, 2),
       (4, 1),
       (4, 2),
       (5, 1),
       (5, 3),
       (6, 1),
       (6, 3),
       (7, 1),
       (7, 3);
-- select * from journal;
*/

--data bug
/*
insert into groups_to_events ("group", event)
values (1, 1),
       (2, 2),
       (3, 3);
-- select * from groups_to_events;
 */

insert into groups_to_schedule ("group", event_in_schedule)
values (1, 1),
       (2, 4),
       (3, 5),
       (4, 3);
--  select * from groups_to_schedule;

--data examples block end

