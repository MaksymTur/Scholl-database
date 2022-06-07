--type block

CREATE TYPE week_day AS enum ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

--type block end
--table block

CREATE TABLE rooms
(
    title     varchar(20) NOT NULL,
    room_type varchar(20) NOT NULL,
    seats     integer     NOT NULL,
    room_id   serial,

    UNIQUE (title),
    PRIMARY KEY (room_id)
);

CREATE TABLE subjects
(
    title      varchar(20) NOT NULL,
    subject_id serial,

    PRIMARY KEY (subject_id)
);

CREATE TABLE pupils
(
    date_of_birth date        NOT NULL,
    first_name    varchar(20) NOT NULL,
    last_name     varchar(20) NOT NULL,
    pupil_id      serial,

    PRIMARY KEY (pupil_id)
);


CREATE TABLE themes
(
    title          varchar(40)             NOT NULL,
    subject_id     int REFERENCES subjects NOT NULL,
    lessons_length integer                 NOT NULL,
    theme_order    integer                 NOT NULL,
    theme_id       serial,

    UNIQUE (title, subject_id),
    UNIQUE (subject_id, theme_order),
    PRIMARY KEY (theme_id)
);

CREATE TABLE excuses
(
    pupil_id   int REFERENCES pupils NOT NULL,
    reason     text,
    begin_date date                  NOT NULL,
    begin_bell int,
    end_date   date                  NOT NULL,
    end_bell   int,
    excuse_id  serial,

    PRIMARY KEY (excuse_id)
);

CREATE TABLE bell_schedule_history
(
    bell_order  int,
    begin_time  time               NOT NULL,
    end_time    time               NOT NULL,
    change_date date DEFAULT now() NOT NULL,
    change_id   serial,

    PRIMARY KEY (change_id)
);

CREATE TABLE "groups"
(
    title      varchar(40)                 NOT NULL,
    subject_id integer REFERENCES subjects NOT NULL,
    group_id   serial,

    PRIMARY KEY (group_id)
);

CREATE TABLE groups_history
(
    pupil_id   int REFERENCES pupils   NOT NULL,
    group_id   int REFERENCES "groups" NOT NULL,
    begin_time timestamp DEFAULT now() NOT NULL,
    end_time   timestamp DEFAULT NULL,
    change_id  serial,

    PRIMARY KEY (change_id)
);

CREATE TABLE employees
(
    first_name  varchar(20),
    last_name   varchar(20),
    employee_id serial,

    PRIMARY KEY (employee_id)
);

CREATE TABLE posts
(
    title   varchar(20),
    post_id serial,

    PRIMARY KEY (post_id)
);


CREATE TABLE employees_history
(
    employee_id int REFERENCES employees NOT NULL,
    post_id     int REFERENCES posts     NOT NULL,
    begin_time  timestamp                NOT NULL,
    end_time    timestamp DEFAULT NULL,

    PRIMARY KEY (employee_id, post_id, begin_time)
);

CREATE TABLE schedule_history
(
    teacher_id          integer REFERENCES employees NOT NULL,
    room_id             integer REFERENCES rooms,
    subject_id          integer REFERENCES subjects,
    bell_order          integer,
    "week_day"          week_day                     NOT NULL,
    is_odd_week         bool,
    change_date         date DEFAULT now()           NOT NULL,
    schedule_history_id serial,

    UNIQUE (teacher_id, room_id, bell_order, "week_day", is_odd_week, change_date),
    PRIMARY KEY (schedule_history_id)
);

CREATE TABLE events
(
    room_id    integer REFERENCES rooms,
    teacher_id integer REFERENCES employees NOT NULL,
    theme_id   integer REFERENCES themes,
    event_date date DEFAULT now()           NOT NULL,
    event_bell int                          NOT NULL,
    event_id   serial,

    UNIQUE (teacher_id, event_date, event_bell),
    UNIQUE (room_id, event_date, event_bell),
    PRIMARY KEY (event_id)
);

CREATE TABLE mark_types
(
    type_name varchar(10) NOT NULL,
    type_id   serial,

    PRIMARY KEY (type_id)
);

CREATE TABLE type_weights_history
(
    type_id     integer REFERENCES mark_types NOT NULL,
    change_date date                          NOT NULL,
    weight      numeric(5, 2),

    PRIMARY KEY (type_id, change_date)
);

CREATE TABLE marks
(
    pupil_id integer REFERENCES pupils     NOT NULL,
    event_id integer REFERENCES events     NOT NULL,
    mark     integer                       NOT NULL,
    type_id  integer REFERENCES mark_types NOT NULL,
    mark_id  serial,

    PRIMARY KEY (mark_id)
);

CREATE TABLE quarters
(
    begin_date date NOT NULL,
    end_date   date NOT NULL,
    quarter_id serial,

    PRIMARY KEY (quarter_id)
);

CREATE TABLE holidays
(
    begin_date  date NOT NULL,
    end_date    date NOT NULL,
    holidays_id serial,

    PRIMARY KEY (holidays_id)
);

CREATE TABLE salary_history
(
    employee_id int REFERENCES employees NOT NULL,
    salary      int                      NOT NULL,
    change_time timestamp                NOT NULL,

    PRIMARY KEY (employee_id, change_time)
);

CREATE TABLE classes
(
    title      varchar(10) NOT NULL,
    study_year int         NOT NULL,
    class_id   serial,

    PRIMARY KEY (class_id)
);

CREATE TABLE class_history
(
    pupil_id    int REFERENCES pupils   NOT NULL,
    class_id    int REFERENCES classes,
    change_time timestamp DEFAULT NOW() NOT NULL,

    PRIMARY KEY (pupil_id, class_id, change_time)
);

CREATE TABLE class_teacher_history
(
    class_id    int REFERENCES classes   NOT NULL,
    teacher_id  int REFERENCES employees NOT NULL,
    change_time timestamp                NOT NULL,

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
    group_id int REFERENCES groups NOT NULL,
    event_id int REFERENCES events NOT NULL,

    PRIMARY KEY (group_id, event_id)
);

CREATE TABLE groups_to_schedule
(
    group_id             int REFERENCES groups           NOT NULL,
    event_in_schedule_id int REFERENCES schedule_history NOT NULL,

    PRIMARY KEY (group_id, event_in_schedule_id)
);

--table block end
-- functions block

CREATE FUNCTION get_week_day(at_date date = NOW()::date)
    RETURNS week_day AS
$$
declare
    a integer;
begin
    a = extract(isodow from at_date);
    if (a = 1) then
        return 'Monday';
    elseif (a = 2) then
        return 'Tuesday';
    elseif (a = 3) then
        return 'Wednesday';
    elseif (a = 4) then
        return 'Thursday';
    elseif (a = 5) then
        return 'Friday';
    elseif (a = 6) then
        return 'Saturday';
    else
        return 'Sunday';
    end if;
end;
$$ language plpgsql;

CREATE FUNCTION has_post(employee int, post int, check_time timestamp DEFAULT now())
    RETURNS bool AS
$$
begin
    return (SELECT COUNT(*)
            FROM employees_history
            WHERE employee_id = employee
              AND post_id = post
              AND begin_time <= check_time
              AND (end_time IS NULL OR end_time > check_time)) = 1;
end;
$$ language plpgsql;

CREATE FUNCTION add_post(employee int, post int)
    RETURNS bool AS
$$
begin
    if has_post(employee, post) then
        return false;
    end if;
    INSERT INTO employees_history(employee_id, post_id, begin_time)
    VALUES (employee, post, now());
    return true;
end
$$ language plpgsql;

CREATE FUNCTION delete_post(employee int, post int)
    RETURNS bool AS
$$
begin
    if not has_post(employee, post) then
        return false;
    end if;
    UPDATE employees_history
    SET end_time = now()
    WHERE end_time IS NULL
      AND employee_id = employee
      AND post_id = post;
    return true;
end
$$ language plpgsql;

CREATE FUNCTION study_start(pupil_id int)
    RETURNS timestamp AS
$$
begin
    SELECT change_time
    FROM class_history
    WHERE class_history.pupil_id = study_start.pupil_id
    ORDER BY 1
    LIMIT 1;
end
$$ language plpgsql;

CREATE FUNCTION work_start(employee_id int)
    RETURNS timestamp AS
$$
begin
    SELECT begin_time
    FROM employees_history
    WHERE employees_history.employee_id = work_start.employee_id
    ORDER BY 1
    LIMIT 1;
end
$$ language plpgsql;

CREATE FUNCTION bell_begin_time(bell_date date, bell_order int)
    RETURNS timestamp AS
$$
begin
    if (bell_order IS NULL) then
        return bell_date;
    end if;
    return bell_date + (SELECT begin_time
                        FROM bell_schedule_history
                        WHERE change_date < bell_date
                          AND bell_schedule_history.bell_order = bell_begin_time.bell_order
                        ORDER BY change_date DESC
                        LIMIT 1);
end
$$ language plpgsql;

CREATE FUNCTION bell_end_time(bell_date date, bell_order int)
    RETURNS timestamp AS
$$
begin
    return bell_date + (SELECT end_time
                        FROM bell_schedule_history
                        WHERE change_date < bell_date
                          AND bell_schedule_history.bell_order = bell_end_time.bell_order
                        ORDER BY change_date DESC
                        LIMIT 1);
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

CREATE FUNCTION is_studying(pupil_id int, at_time timestamp)
    RETURNS boolean AS
$$
begin
    return (SELECT class_history.class_id
            FROM class_history
            WHERE class_history.pupil_id = is_studying.pupil_id
              AND class_history.change_time <= is_studying.at_time
            ORDER BY change_time DESC
            LIMIT 1) IS NOT NULL;
end
$$ language plpgsql;

CREATE FUNCTION is_working(employee_id int, at_time timestamp)
    RETURNS boolean AS
$$
begin
    return EXISTS(SELECT *
                  FROM employees_history
                  WHERE employees_history.employee_id = is_working.employee_id
                    AND employees_history.begin_time <= is_working.at_time
                    AND (employees_history.end_time IS NULL OR employees_history.end_time >= at_time));
end
$$ language plpgsql;

CREATE FUNCTION get_bells_schedule(at_date date)
    RETURNS table
            (
                bell_order int,
                begin_time timestamp,
                end_time   timestamp
            )
AS
$$
begin
    return query
        SELECT sch.bell_order, bell_begin_time(at_date, sch.bell_order), bell_end_time(at_date, sch.bell_order)
        FROM bell_schedule_history sch
        WHERE bell_begin_time(at_date, sch.bell_order) IS NOT NULL
        GROUP BY sch.bell_order, at_date
        ORDER BY 1;
end;
$$ language plpgsql;

CREATE FUNCTION get_quarter_begin(at_date date)
    RETURNS date AS
$$
begin
    return (SELECT quarters.begin_date
            FROM quarters
            WHERE begin_date <= at_date
            ORDER BY begin_date DESC
            LIMIT 1);
end;
$$ language plpgsql;

CREATE FUNCTION get_quarter_end(at_date date)
    RETURNS date AS
$$
begin
    return (SELECT quarters.end_date
            FROM quarters
            WHERE begin_date <= at_date
            ORDER BY begin_date DESC
            LIMIT 1);
end;
$$ language plpgsql;

CREATE FUNCTION get_parity(at_date date)
    RETURNS boolean AS
$$
begin
    return ((extract(epoch from date_trunc('week', at_date)) -
             extract(epoch from date_trunc('week', get_quarter_begin(at_date)))) / 604800)::integer % 2 = 0;
end;
$$ language plpgsql;

CREATE FUNCTION get_schedule(at_date date)
    RETURNS table
            (
                teacher_id integer,
                room_id    integer,
                bell_order integer,
                subject_id integer
            )
AS
$$
begin
    return query SELECT outer_h.teacher_id, outer_h.room_id, outer_h.bell_order, outer_h.subject_id
                 FROM schedule_history outer_h
                 WHERE outer_h.subject_id IS NOT NULL
                   AND outer_h.change_date <= at_date
                   AND outer_h.week_day = get_week_day(at_date)
                   AND (outer_h.is_odd_week IS NULL OR is_odd_week = get_parity(at_date))
                   AND outer_h.change_date = (SELECT MAX(inner_h.change_date)
                                              FROM schedule_history inner_h
                                              WHERE inner_h.change_date <= at_date
                                                AND inner_h.week_day = outer_h.week_day
                                                AND (inner_h.is_odd_week IS NULL OR
                                                     inner_h.is_odd_week = get_parity(at_date))
                                                AND inner_h.teacher_id = outer_h.teacher_id
                                                AND inner_h.bell_order = outer_h.bell_order);
end;
$$ language plpgsql;

CREATE FUNCTION add_bell(bell_order integer, begin_time time, end_time time, change_time timestamp = NOW())
    RETURNS void AS
$$
begin
    if ((SELECT sch.begin_time
         FROM get_bells_schedule(change_time::date) sch
         WHERE sch.bell_order = add_bell.bell_order) <= change_time::time) then
        INSERT INTO bell_schedule_history (bell_order, begin_time, end_time, change_date)
        VALUES (add_bell.bell_order, add_bell.begin_time, add_bell.end_time,
                add_bell.change_time::date + INTERVAL '1 day');
    else
        INSERT INTO bell_schedule_history (bell_order, begin_time, end_time, change_date)
        VALUES (add_bell.bell_order, add_bell.begin_time, add_bell.end_time, add_bell.change_time::date);
    end if;
end;
$$ language plpgsql;

CREATE FUNCTION get_schedule(week_day1 week_day, is_odd_week1 boolean, last_change_date1 date)
    RETURNS table
            (
                teacher_id integer,
                room_id    integer,
                bell_order integer,
                subject_id integer
            )
AS
$$
begin
    return query SELECT outer_h.teacher_id, outer_h.room_id, outer_h.bell_order, outer_h.subject_id
                 FROM schedule_history outer_h
                 WHERE outer_h.subject_id IS NOT NULL
                   AND outer_h.change_date <= last_change_date1
                   AND outer_h.week_day = week_day1
                   AND (outer_h.is_odd_week IS NULL OR outer_h.is_odd_week = is_odd_week1 OR is_odd_week1 IS NULL)
                   AND outer_h.change_date = (SELECT MAX(change_date)
                                              FROM schedule_history inner_h
                                              WHERE inner_h.change_date <= last_change_date1
                                                  AND week_day1 = outer_h.week_day
                                                  AND inner_h.is_odd_week IS NULL
                                                 OR inner_h.is_odd_week = is_odd_week1
                                                 OR is_odd_week1 IS NULL
                                                  AND inner_h.teacher_id = outer_h.teacher_id
                                                  AND inner_h.bell_order = outer_h.bell_order);
end;
$$ language plpgsql;

CREATE FUNCTION add_to_schedule(teacher_id integer, room_id integer, bell_order integer, week_day week_day,
                                is_odd_week boolean, change_time timestamp = NOW())
    RETURNS void AS
$$
declare
    at_date date;
begin
    at_date := change_time::date;
    if (get_week_day(at_date) = week_day
        AND (is_odd_week IS NULL OR get_parity(at_date) = is_odd_week)
        AND bell_begin_time(at_date, bell_order) <= change_time::time) then
        INSERT INTO schedule_history (teacher_id, room_id, bell_order, week_day, is_odd_week, change_date)
        VALUES (add_to_schedule.teacher_id, add_to_schedule.room_id, add_to_schedule.bell_order,
                add_to_schedule.week_day, add_to_schedule.is_odd_week,
                add_to_schedule.change_time::date + INTERVAL '1 day');
    else
        INSERT INTO schedule_history (teacher_id, room_id, bell_order, week_day, is_odd_week, change_date)
        VALUES (add_to_schedule.teacher_id, add_to_schedule.room_id, add_to_schedule.bell_order,
                add_to_schedule.week_day, add_to_schedule.is_odd_week,
                add_to_schedule.change_time::date);
    end if;
end;
$$ language plpgsql;

CREATE FUNCTION get_pupils_from_group(group_id1 integer, at_time timestamp)
    RETURNS table
            (
                pupil_id integer
            )
AS
$$
begin
    return query (SELECT h.pupil_id
                  FROM groups_history h
                  WHERE begin_time <= at_time
                    AND end_time > at_time
                    AND h.group_id = group_id1);
end;
$$ language plpgsql;

CREATE FUNCTION get_groups_from_event(event_id1 integer)
    RETURNS table
            (
                group_id integer
            )
AS
$$
begin
    return query (SELECT group_id
                  FROM groups_to_events
                  WHERE groups_to_events.event_id = event_id1);
end;
$$ language plpgsql;

CREATE FUNCTION get_groups_of_pupil(pupil_id1 integer, at_time timestamp)
    RETURNS table
            (
                group_id integer
            )
AS
$$
begin
    return query (SELECT groups_history.group_id
                  FROM groups_history
                  WHERE begin_time <= at_time
                    AND end_time > at_time
                    AND groups_history.pupil_id = pupil_id1);
end;
$$ language plpgsql;

CREATE FUNCTION delete_from_group(pupil_id integer, group_id integer, deletion_time timestamp)
    RETURNS void
AS
$$
declare
    to_del integer;
begin
    if (NOT EXISTS(SELECT *
                   FROM get_groups_of_pupil(pupil_id, deletion_time) sl
                   WHERE sl.group_id = delete_from_group.group_id)) then
        return;
    end if;
    to_del := (SELECT change_id
               FROM groups_history
               WHERE groups_history.pupil_id = delete_from_group.pupil_id
                 AND groups_history.group_id = delete_from_group.group_id
               ORDER BY begin_time DESC
               LIMIT 1);
    UPDATE groups_history
    SET end_time = deletion_time
    WHERE change_id = to_del;
end;
$$ language plpgsql;

CREATE FUNCTION get_mark_from_theme(pupil_id integer, theme_id integer)
    RETURNS numeric(5, 3)
AS
$$
declare
    i record;
    a numeric(5, 3);
    b numeric(5, 3);
begin
    a := 0;
    b := 0;
    for i in (SELECT *
              FROM marks NATURAL JOIN events NATURAL JOIN type_weights_history
              WHERE events.theme_id = get_mark_from_theme.theme_id
                AND marks.pupil_id = get_mark_from_theme.pupil_id)
        loop
            a := a + i.weight * i.mark;
            b := b + i.weight;
        end loop;
    if b = 0 then
        return 1;
    end if;
    return a / b;
end;
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
    ADD CONSTRAINT excuses_excuse_in_study_time
        CHECK (
                is_studying(pupil_id, bell_begin_time(begin_date, begin_bell)) AND
                is_studying(pupil_id, bell_begin_time(end_date, end_bell))
            );

ALTER TABLE bell_schedule_history
    ADD CONSTRAINT bell_schedule_history_normal_length_check
        CHECK (
            begin_time < end_time
            );

CREATE FUNCTION bell_schedule_history_insert_trigger()
    RETURNS TRIGGER AS
$$
declare
    bell_order int;
    begin_time timestamp;
    end_time   timestamp;
begin
    for bell_order, begin_time, end_time in (SELECT get_bells_schedule(NEW.change_date::date))
        loop
            if (bell_order != NEW.bell_order AND NOT (NEW.begin_time > end_time OR begin_time > NEW.end_time)) then
                return NULL;
            end if;
        end loop;
    return NEW;
end;
$$
    LANGUAGE PLPGSQL;

CREATE TRIGGER bell_schedule_history_non_intersect_trigger
    BEFORE INSERT
    ON bell_schedule_history
    FOR EACH ROW
EXECUTE PROCEDURE bell_schedule_history_insert_trigger();

ALTER TABLE groups_history
    ADD CONSTRAINT groups_history_add_before_deletion_check
        CHECK (
            begin_time < end_time
            );

ALTER TABLE employees_history
    ADD CONSTRAINT employees_history_add_before_deletion_check
        CHECK (
            begin_time < end_time
            );

ALTER TABLE schedule_history
    ADD CONSTRAINT schedule_history_bell_order_exists
        CHECK (
            bell_begin_time(change_date, bell_order) IS NOT NULL
            );

CREATE OR REPLACE FUNCTION schedule_history_insert_trigger()
    RETURNS TRIGGER AS
$$
declare
    i record;
begin
    for i in (SELECT * FROM get_schedule(NEW.week_day, NEW.is_odd_week, NEW.change_date))
        loop
            if (NEW.bell_order = i.bell_order
                AND NEW.room_id = i.room_id
                AND NEW.teacher_id != i.teacher_id) then
                return NULL;
            end if;
        end loop;
    return NEW;
end;
$$
    LANGUAGE PLPGSQL;

CREATE TRIGGER schedule_history_non_intersect_trigger
    BEFORE INSERT
    ON schedule_history
    FOR EACH ROW
EXECUTE PROCEDURE schedule_history_insert_trigger();

ALTER TABLE events
    ADD CONSTRAINT events_bell_exists_check
        CHECK (
            bell_begin_time(event_date, event_bell) IS NOT NULL
            );

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

CREATE FUNCTION quarters_insert_trigger()
    RETURNS TRIGGER AS
$$
declare
    i record;
begin
    for i in (SELECT * FROM quarters)
        loop
            if (NOT (NEW.begin_date > i.end_date OR i.begin_date > NEW.end_date)) then
                return NULL;
            end if;
        end loop;
    return NEW;
end;
$$
    LANGUAGE PLPGSQL;

CREATE TRIGGER quarters_non_intersect_trigger
    BEFORE INSERT
    ON quarters
    FOR EACH ROW
EXECUTE PROCEDURE quarters_insert_trigger();

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

CREATE FUNCTION holidays_insert_trigger()
    RETURNS TRIGGER AS
$$
declare
    i record;
begin
    for i in (SELECT * FROM holidays)
        loop
            if (NOT (NEW.begin_date > i.end_date OR i.begin_date > NEW.end_date)) then
                return NULL;
            end if;
        end loop;
    return NEW;
end;
$$
    LANGUAGE PLPGSQL;

CREATE TRIGGER holidays_non_intersect_trigger
    BEFORE INSERT
    ON holidays
    FOR EACH ROW
EXECUTE PROCEDURE holidays_insert_trigger();

ALTER TABLE salary_history
    ADD CONSTRAINT salary_history_salary_positive_check
        CHECK (
            salary > 0
            );

ALTER TABLE salary_history
    ADD CONSTRAINT salary_history_salary_while_working
        CHECK (
            is_working(employee_id, change_time)
            );

ALTER TABLE classes
    ADD CONSTRAINT classes_normal_study_year_check
        CHECK (
            study_year > 0 AND study_year < 13
            );

ALTER TABLE class_teacher_history
    ADD CONSTRAINT class_teacher_history_class_teacher_only_at_work_time
        CHECK (
            is_working(teacher_id, change_time)
            );

CREATE FUNCTION journal_insert_trigger()
    RETURNS TRIGGER AS
$$
declare
    i         integer;
    should_be boolean;
begin
    should_be := false;
    for i in (SELECT get_groups_from_event(NEW.event_id))
        loop
            if (EXISTS(SELECT pupils.pupil_id
                       FROM get_pupils_from_group(i, NOW()) pupils
                       WHERE pupils.pupil_id = NEW.pupil_id)) then
                should_be := true;
            end if;
        end loop;
    if should_be = true then
        return NEW;
    else
        return NULL;
    end if;
end;
$$
    LANGUAGE PLPGSQL;

CREATE TRIGGER journal_pupil_from_group_on_event
    BEFORE INSERT
    ON journal
    FOR EACH ROW
EXECUTE PROCEDURE journal_insert_trigger();

CREATE FUNCTION groups_to_events_delete_trigger()
    RETURNS TRIGGER AS
$$
declare
    i integer;
begin
    for i in (SELECT get_pupils_from_group(OLD.group_id, bell_begin_time(
            (SELECT event_date FROM events WHERE events.event_id = OLD.event_id),
            (SELECT event_bell FROM events WHERE events.event_id = OLD.event_id))))
        loop
            DELETE
            FROM journal
            WHERE pupil_id = i
              AND journal.event_id = OLD.event_id;
        end loop;
    return OLD;
end;
$$
    LANGUAGE PLPGSQL;

CREATE TRIGGER groups_to_events_delete_from_journal_on_delete
    BEFORE INSERT
    ON groups_to_events
    FOR EACH ROW
EXECUTE PROCEDURE groups_to_events_delete_trigger();

--checkers and triggers block end
--indexes block

CREATE INDEX
    ON rooms (room_type);

CREATE INDEX
    ON pupils (date_of_birth);

CREATE INDEX
    ON themes (theme_order);

CREATE INDEX
    ON excuses (begin_date, begin_bell, end_date, end_bell);

CREATE INDEX
    ON bell_schedule_history (change_date);

CREATE INDEX
    ON schedule_history (change_date);

CREATE INDEX
    ON schedule_history (change_date);

CREATE INDEX
    ON events (event_date, event_bell);

CREATE INDEX
    ON type_weights_history (change_date);

CREATE INDEX
    ON quarters (begin_date, end_date);

CREATE INDEX
    ON holidays (begin_date, end_date);

CREATE INDEX
    ON salary_history (change_time);

CREATE INDEX
    ON class_history (change_time);

CREATE INDEX
    ON class_teacher_history (change_time);

--indexes block end

--data final block

insert into quarters (begin_date, end_date)
values ('2021-09-01', '2021-10-30'),
       ('2021-11-08', '2021-12-24'),
       ('2022-01-10', '2022-04-26'),
       ('2022-04-04', '2022-05-31');

insert into holidays (begin_date, end_date)
values ('2021-10-31', '2021-11-07'),
       ('2021-12-25', '2022-01-09'),
       ('2022-04-27', '2022-05-03'),
       ('2022-06-01', '2022-08-31');

insert into bell_schedule_history (bell_order, begin_time, end_time, change_date)
values (1, '08:00', '08:45', '2015-01-01'),
       (2, '09:00', '09:45', '2015-01-01'),
       (3, '09:55', '10:40', '2015-01-01'),
       (4, '10:55', '11:40', '2015-01-01'),
       (5, '12:00', '12:45', '2015-01-01'),
       (6, '13:05', '13:50', '2015-01-01'),
       (7, '14:05', '14:50', '2015-01-01');

insert into mark_types (type_name)
values ('exam'),
       ('project'),
       ('test'),
       ('homework');

insert into type_weights_history (type_id, change_date, weight)
values (1, '2021-08-31', 1.00),
       (2, '2021-08-31', 0.50),
       (3, '2021-08-31', 0.30),
       (4, '2021-08-31', 0.15);

insert into pupils (date_of_birth, first_name, last_name)
values ('2006-06-10', 'Ellice', 'Fischer'),
       ('2006-06-26', 'Chase', 'Harrell'),
       ('2006-06-30', 'Elijah', 'Murillo'),
       ('2006-07-07', 'Clelia', 'Stuart'),
       ('2006-07-14', 'Aiden', 'Oneal'),
       ('2006-07-20', 'Apollo', 'Mckenzie'),
       ('2006-07-23', 'Candice', 'Mcbride'),
       ('2006-07-26', 'Coralie', 'Cunningham'),
       ('2006-07-27', 'Timothy', 'Hooper'),
       ('2006-08-23', 'Ellice', 'Mills'),
       ('2006-08-26', 'Randall', 'Lang'),
       ('2006-08-30', 'Dezi', 'Burns'),
       ('2006-09-06', 'Sutton', 'Williamson'),
       ('2006-09-12', 'Elodie', 'Mills'),
       ('2006-09-14', 'Syllable', 'Mcguire'),
       ('2006-09-20', 'Jacklyn', 'Salazar'),
       ('2006-10-02', 'Gwendolen', 'Merritt'),
       ('2006-10-03', 'Matilda', 'Garrison'),
       ('2006-10-19', 'Mirabel', 'Preston'),
       ('2006-10-23', 'Cameron', 'Dougherty'),
       ('2006-10-29', 'Devon', 'Baird'),
       ('2006-11-30', 'Jeremy', 'Krueger'),
       ('2006-12-01', 'Reeve', 'Taylor'),
       ('2006-12-13', 'Robert', 'Levine'),
       ('2007-01-14', 'Clelia', 'Pollard'),
       ('2006-06-09', 'Kai', 'Watson'),
       ('2006-06-29', 'June', 'Kemp'),
       ('2006-06-30', 'Jackson', 'Moody'),
       ('2006-07-03', 'Ellory', 'Davenport'),
       ('2006-07-13', 'Arden', 'Powers'),
       ('2006-07-16', 'Sherleen', 'Durham'),
       ('2006-07-18', 'Heath', 'Mccoy'),
       ('2006-07-21', 'Fawn', 'Wiggins'),
       ('2006-07-23', 'Caprice', 'Zhang'),
       ('2006-08-26', 'Lee', 'Mathis'),
       ('2006-09-23', 'Gavin', 'Riley'),
       ('2006-10-16', 'Leonie', 'Murphy'),
       ('2006-10-23', 'Brighton', 'Pham'),
       ('2006-11-20', 'Anise', 'Hayden'),
       ('2006-11-26', 'June', 'Nolan'),
       ('2006-12-14', 'Raine', 'Watkins'),
       ('2006-12-21', 'Blaise', 'Jacobs'),
       ('2006-12-27', 'Gwendolen', 'Hanson'),
       ('2006-12-29', 'Dustin', 'Baker'),
       ('2007-01-01', 'Finn', 'Webster'),
       ('2007-01-08', 'Louisa', 'Buck'),
       ('2007-01-16', 'Lane', 'Ramsey'),
       ('2006-06-06', 'Juliet', 'Rollins'),
       ('2006-06-10', 'Tristan', 'Dunn'),
       ('2006-06-12', 'Vernon', 'Smith'),
       ('2006-06-14', 'William', 'Baker'),
       ('2006-06-19', 'Brendon', 'Thompson'),
       ('2006-07-03', 'Blaise', 'Pearson'),
       ('2006-07-05', 'Chase', 'Rich'),
       ('2006-07-07', 'Rosalind', 'Davis'),
       ('2006-07-26', 'Evelyn', 'Young'),
       ('2006-08-15', 'Linnea', 'Young'),
       ('2006-09-01', 'Levi', 'Holland'),
       ('2006-09-08', 'Clark', 'Cain'),
       ('2006-09-24', 'Zane', 'Bright');

insert into subjects (title)
values ('Debate'),
       ('Polish'),
       ('English'),
       ('Foreign language II'),
       ('Mathematics'),
       ('Biology'),
       ('Chemistry'),
       ('Physics'),
       ('Geography'),
       ('Informatics'),
       ('History'),
       ('Civics');

insert into themes (title, subject_id, lessons_length, theme_order)
values ('BlackLivesMatter', 1, 20, 1),
       ('DoesTheGodExist', 1, 20, 2),
       ('Grammar', 2, 10, 1),
       ('Reading', 2, 20, 2),
       ('Speaking', 2, 10, 3),
       ('Grammar', 3, 10, 1),
       ('Reading', 3, 20, 2),
       ('Speaking', 3, 10, 3),
       ('Grammar', 4, 10, 1),
       ('Reading', 4, 20, 2),
       ('Speaking', 4, 10, 3),
       ('Geometry', 5, 15, 1),
       ('Algebra', 5, 20, 2),
       ('Anatomy', 6, 20, 1),
       ('Heredity And Evolution', 6, 20, 2),
       ('Lab', 8, 20, 1),
       ('Theory', 8, 20, 2),
       ('Countries', 9, 20, 1),
       ('Environment', 9, 20, 2),
       ('C++', 10, 20, 1),
       ('Python', 10, 20, 2),
       ('World', 11, 20, 1),
       ('Poland', 11, 20, 2),
       ('Politics', 12, 20, 2),
       ('Laws', 12, 20, 1);

insert into groups (title, subject_id)
values ('Debate 11A 1', 1),
       ('Debate 11A 2', 1),
       ('Polish 11A 1', 2),
       ('Polish 11A 2', 2),
       ('English 11A 1', 3),
       ('English 11A 2', 3),
       ('Foreign languageII 11A 1', 4),
       ('Foreign languageII 11A 2', 4),
       ('Mathematics 11A 1', 5),
       ('Biology 11A 1', 6),
       ('Chemistry 11A 1', 7),
       ('Physics 11A 1', 8),
       ('Geography 11A 1', 9),
       ('Informatics 11A 1', 10),
       ('Informatics 11A 2', 10),
       ('History 11A 1', 11),
       ('Civics 11A 1', 12),
       ('Debate 11B 1', 1),
       ('Debate 11B 2', 1),
       ('Polish 11B 1', 2),
       ('Polish 11B 2', 2),
       ('English 11B 1', 3),
       ('English 11B 2', 3),
       ('Foreign languageII 11B 1', 4),
       ('Foreign languageII 11B 2', 4),
       ('Mathematics 11B 1', 5),
       ('Biology 11B 1', 6),
       ('Chemistry 11B 1', 7),
       ('Physics 11B 1', 8),
       ('Geography 11B 1', 9),
       ('Informatics 11B 1', 10),
       ('Informatics 11B 2', 10),
       ('History 11B 1', 11),
       ('Civics 11B 1', 12),
       ('Debate 11C 1', 1),
       ('Debate 11C 2', 1),
       ('Polish 11C 1', 2),
       ('Polish 11C 2', 2),
       ('English 11C 1', 3),
       ('English 11C 2', 3),
       ('Foreign languageII 11C 1', 4),
       ('Foreign languageII 11C 2', 4),
       ('Mathematics 11C 1', 5),
       ('Biology 11C 1', 6),
       ('Chemistry 11C 1', 7),
       ('Physics 11C 1', 8),
       ('Geography 11C 1', 9),
       ('Informatics 11C 1', 10),
       ('Informatics 11C 2', 10),
       ('History 11C 1', 11),
       ('Civics 11C 1', 12);


insert into groups_history (pupil_id, group_id, begin_time)
values (1, 1, '2021-08-31 11:00:00'),
       (1, 3, '2021-08-31 11:00:00'),
       (1, 5, '2021-08-31 11:00:00'),
       (1, 7, '2021-08-31 11:00:00'),
       (1, 9, '2021-08-31 11:00:00'),
       (1, 10, '2021-08-31 11:00:00'),
       (1, 11, '2021-08-31 11:00:00'),
       (1, 12, '2021-08-31 11:00:00'),
       (1, 13, '2021-08-31 11:00:00'),
       (1, 14, '2021-08-31 11:00:00'),
       (1, 16, '2021-08-31 11:00:00'),
       (1, 17, '2021-08-31 11:00:00'),
       (2, 2, '2021-08-31 11:00:00'),
       (2, 4, '2021-08-31 11:00:00'),
       (2, 6, '2021-08-31 11:00:00'),
       (2, 8, '2021-08-31 11:00:00'),
       (2, 9, '2021-08-31 11:00:00'),
       (2, 10, '2021-08-31 11:00:00'),
       (2, 11, '2021-08-31 11:00:00'),
       (2, 12, '2021-08-31 11:00:00'),
       (2, 13, '2021-08-31 11:00:00'),
       (2, 15, '2021-08-31 11:00:00'),
       (2, 16, '2021-08-31 11:00:00'),
       (2, 17, '2021-08-31 11:00:00'),
       (3, 1, '2021-08-31 11:00:00'),
       (3, 3, '2021-08-31 11:00:00'),
       (3, 5, '2021-08-31 11:00:00'),
       (3, 7, '2021-08-31 11:00:00'),
       (3, 9, '2021-08-31 11:00:00'),
       (3, 10, '2021-08-31 11:00:00'),
       (3, 11, '2021-08-31 11:00:00'),
       (3, 12, '2021-08-31 11:00:00'),
       (3, 13, '2021-08-31 11:00:00'),
       (3, 14, '2021-08-31 11:00:00'),
       (3, 16, '2021-08-31 11:00:00'),
       (3, 17, '2021-08-31 11:00:00'),
       (4, 2, '2021-08-31 11:00:00'),
       (4, 4, '2021-08-31 11:00:00'),
       (4, 6, '2021-08-31 11:00:00'),
       (4, 8, '2021-08-31 11:00:00'),
       (4, 9, '2021-08-31 11:00:00'),
       (4, 10, '2021-08-31 11:00:00'),
       (4, 11, '2021-08-31 11:00:00'),
       (4, 12, '2021-08-31 11:00:00'),
       (4, 13, '2021-08-31 11:00:00'),
       (4, 15, '2021-08-31 11:00:00'),
       (4, 16, '2021-08-31 11:00:00'),
       (4, 17, '2021-08-31 11:00:00'),
       (5, 1, '2021-08-31 11:00:00'),
       (5, 3, '2021-08-31 11:00:00'),
       (5, 5, '2021-08-31 11:00:00'),
       (5, 7, '2021-08-31 11:00:00'),
       (5, 9, '2021-08-31 11:00:00'),
       (5, 10, '2021-08-31 11:00:00'),
       (5, 11, '2021-08-31 11:00:00'),
       (5, 12, '2021-08-31 11:00:00'),
       (5, 13, '2021-08-31 11:00:00'),
       (5, 14, '2021-08-31 11:00:00'),
       (5, 16, '2021-08-31 11:00:00'),
       (5, 17, '2021-08-31 11:00:00'),
       (6, 2, '2021-08-31 11:00:00'),
       (6, 4, '2021-08-31 11:00:00'),
       (6, 6, '2021-08-31 11:00:00'),
       (6, 8, '2021-08-31 11:00:00'),
       (6, 9, '2021-08-31 11:00:00'),
       (6, 10, '2021-08-31 11:00:00'),
       (6, 11, '2021-08-31 11:00:00'),
       (6, 12, '2021-08-31 11:00:00'),
       (6, 13, '2021-08-31 11:00:00'),
       (6, 15, '2021-08-31 11:00:00'),
       (6, 16, '2021-08-31 11:00:00'),
       (6, 17, '2021-08-31 11:00:00'),
       (7, 1, '2021-08-31 11:00:00'),
       (7, 3, '2021-08-31 11:00:00'),
       (7, 5, '2021-08-31 11:00:00'),
       (7, 7, '2021-08-31 11:00:00'),
       (7, 9, '2021-08-31 11:00:00'),
       (7, 10, '2021-08-31 11:00:00'),
       (7, 11, '2021-08-31 11:00:00'),
       (7, 12, '2021-08-31 11:00:00'),
       (7, 13, '2021-08-31 11:00:00'),
       (7, 14, '2021-08-31 11:00:00'),
       (7, 16, '2021-08-31 11:00:00'),
       (7, 17, '2021-08-31 11:00:00'),
       (8, 2, '2021-08-31 11:00:00'),
       (8, 4, '2021-08-31 11:00:00'),
       (8, 6, '2021-08-31 11:00:00'),
       (8, 8, '2021-08-31 11:00:00'),
       (8, 9, '2021-08-31 11:00:00'),
       (8, 10, '2021-08-31 11:00:00'),
       (8, 11, '2021-08-31 11:00:00'),
       (8, 12, '2021-08-31 11:00:00'),
       (8, 13, '2021-08-31 11:00:00'),
       (8, 15, '2021-08-31 11:00:00'),
       (8, 16, '2021-08-31 11:00:00'),
       (8, 17, '2021-08-31 11:00:00'),
       (9, 1, '2021-08-31 11:00:00'),
       (9, 3, '2021-08-31 11:00:00'),
       (9, 5, '2021-08-31 11:00:00'),
       (9, 7, '2021-08-31 11:00:00'),
       (9, 9, '2021-08-31 11:00:00'),
       (9, 10, '2021-08-31 11:00:00'),
       (9, 11, '2021-08-31 11:00:00'),
       (9, 12, '2021-08-31 11:00:00'),
       (9, 13, '2021-08-31 11:00:00'),
       (9, 14, '2021-08-31 11:00:00'),
       (9, 16, '2021-08-31 11:00:00'),
       (9, 17, '2021-08-31 11:00:00'),
       (10, 2, '2021-08-31 11:00:00'),
       (10, 4, '2021-08-31 11:00:00'),
       (10, 6, '2021-08-31 11:00:00'),
       (10, 8, '2021-08-31 11:00:00'),
       (10, 9, '2021-08-31 11:00:00'),
       (10, 10, '2021-08-31 11:00:00'),
       (10, 11, '2021-08-31 11:00:00'),
       (10, 12, '2021-08-31 11:00:00'),
       (10, 13, '2021-08-31 11:00:00'),
       (10, 15, '2021-08-31 11:00:00'),
       (10, 16, '2021-08-31 11:00:00'),
       (10, 17, '2021-08-31 11:00:00'),
       (11, 1, '2021-08-31 11:00:00'),
       (11, 3, '2021-08-31 11:00:00'),
       (11, 5, '2021-08-31 11:00:00'),
       (11, 7, '2021-08-31 11:00:00'),
       (11, 9, '2021-08-31 11:00:00'),
       (11, 10, '2021-08-31 11:00:00'),
       (11, 11, '2021-08-31 11:00:00'),
       (11, 12, '2021-08-31 11:00:00'),
       (11, 13, '2021-08-31 11:00:00'),
       (11, 14, '2021-08-31 11:00:00'),
       (11, 16, '2021-08-31 11:00:00'),
       (11, 17, '2021-08-31 11:00:00'),
       (12, 2, '2021-08-31 11:00:00'),
       (12, 4, '2021-08-31 11:00:00'),
       (12, 6, '2021-08-31 11:00:00'),
       (12, 8, '2021-08-31 11:00:00'),
       (12, 9, '2021-08-31 11:00:00'),
       (12, 10, '2021-08-31 11:00:00'),
       (12, 11, '2021-08-31 11:00:00'),
       (12, 12, '2021-08-31 11:00:00'),
       (12, 13, '2021-08-31 11:00:00'),
       (12, 15, '2021-08-31 11:00:00'),
       (12, 16, '2021-08-31 11:00:00'),
       (12, 17, '2021-08-31 11:00:00'),
       (13, 1, '2021-08-31 11:00:00'),
       (13, 3, '2021-08-31 11:00:00'),
       (13, 5, '2021-08-31 11:00:00'),
       (13, 7, '2021-08-31 11:00:00'),
       (13, 9, '2021-08-31 11:00:00'),
       (13, 10, '2021-08-31 11:00:00'),
       (13, 11, '2021-08-31 11:00:00'),
       (13, 12, '2021-08-31 11:00:00'),
       (13, 13, '2021-08-31 11:00:00'),
       (13, 14, '2021-08-31 11:00:00'),
       (13, 16, '2021-08-31 11:00:00'),
       (13, 17, '2021-08-31 11:00:00'),
       (14, 2, '2021-08-31 11:00:00'),
       (14, 4, '2021-08-31 11:00:00'),
       (14, 6, '2021-08-31 11:00:00'),
       (14, 8, '2021-08-31 11:00:00'),
       (14, 9, '2021-08-31 11:00:00'),
       (14, 10, '2021-08-31 11:00:00'),
       (14, 11, '2021-08-31 11:00:00'),
       (14, 12, '2021-08-31 11:00:00'),
       (14, 13, '2021-08-31 11:00:00'),
       (14, 15, '2021-08-31 11:00:00'),
       (14, 16, '2021-08-31 11:00:00'),
       (14, 17, '2021-08-31 11:00:00'),
       (15, 1, '2021-08-31 11:00:00'),
       (15, 3, '2021-08-31 11:00:00'),
       (15, 5, '2021-08-31 11:00:00'),
       (15, 7, '2021-08-31 11:00:00'),
       (15, 9, '2021-08-31 11:00:00'),
       (15, 10, '2021-08-31 11:00:00'),
       (15, 11, '2021-08-31 11:00:00'),
       (15, 12, '2021-08-31 11:00:00'),
       (15, 13, '2021-08-31 11:00:00'),
       (15, 14, '2021-08-31 11:00:00'),
       (15, 16, '2021-08-31 11:00:00'),
       (15, 17, '2021-08-31 11:00:00'),
       (16, 2, '2021-08-31 11:00:00'),
       (16, 4, '2021-08-31 11:00:00'),
       (16, 6, '2021-08-31 11:00:00'),
       (16, 8, '2021-08-31 11:00:00'),
       (16, 9, '2021-08-31 11:00:00'),
       (16, 10, '2021-08-31 11:00:00'),
       (16, 11, '2021-08-31 11:00:00'),
       (16, 12, '2021-08-31 11:00:00'),
       (16, 13, '2021-08-31 11:00:00'),
       (16, 15, '2021-08-31 11:00:00'),
       (16, 16, '2021-08-31 11:00:00'),
       (16, 17, '2021-08-31 11:00:00'),
       (17, 1, '2021-08-31 11:00:00'),
       (17, 3, '2021-08-31 11:00:00'),
       (17, 5, '2021-08-31 11:00:00'),
       (17, 7, '2021-08-31 11:00:00'),
       (17, 9, '2021-08-31 11:00:00'),
       (17, 10, '2021-08-31 11:00:00'),
       (17, 11, '2021-08-31 11:00:00'),
       (17, 12, '2021-08-31 11:00:00'),
       (17, 13, '2021-08-31 11:00:00'),
       (17, 14, '2021-08-31 11:00:00'),
       (17, 16, '2021-08-31 11:00:00'),
       (17, 17, '2021-08-31 11:00:00'),
       (18, 2, '2021-08-31 11:00:00'),
       (18, 4, '2021-08-31 11:00:00'),
       (18, 6, '2021-08-31 11:00:00'),
       (18, 8, '2021-08-31 11:00:00'),
       (18, 9, '2021-08-31 11:00:00'),
       (18, 10, '2021-08-31 11:00:00'),
       (18, 11, '2021-08-31 11:00:00'),
       (18, 12, '2021-08-31 11:00:00'),
       (18, 13, '2021-08-31 11:00:00'),
       (18, 15, '2021-08-31 11:00:00'),
       (18, 16, '2021-08-31 11:00:00'),
       (18, 17, '2021-08-31 11:00:00'),
       (19, 1, '2021-08-31 11:00:00'),
       (19, 3, '2021-08-31 11:00:00'),
       (19, 5, '2021-08-31 11:00:00'),
       (19, 7, '2021-08-31 11:00:00'),
       (19, 9, '2021-08-31 11:00:00'),
       (19, 10, '2021-08-31 11:00:00'),
       (19, 11, '2021-08-31 11:00:00'),
       (19, 12, '2021-08-31 11:00:00'),
       (19, 13, '2021-08-31 11:00:00'),
       (19, 14, '2021-08-31 11:00:00'),
       (19, 16, '2021-08-31 11:00:00'),
       (19, 17, '2021-08-31 11:00:00'),
       (20, 2, '2021-08-31 11:00:00'),
       (20, 4, '2021-08-31 11:00:00'),
       (20, 6, '2021-08-31 11:00:00'),
       (20, 8, '2021-08-31 11:00:00'),
       (20, 9, '2021-08-31 11:00:00'),
       (20, 10, '2021-08-31 11:00:00'),
       (20, 11, '2021-08-31 11:00:00'),
       (20, 12, '2021-08-31 11:00:00'),
       (20, 13, '2021-08-31 11:00:00'),
       (20, 15, '2021-08-31 11:00:00'),
       (20, 16, '2021-08-31 11:00:00'),
       (20, 17, '2021-08-31 11:00:00'),
       (21, 18, '2021-08-31 11:00:00'),
       (21, 20, '2021-08-31 11:00:00'),
       (21, 22, '2021-08-31 11:00:00'),
       (21, 24, '2021-08-31 11:00:00'),
       (21, 26, '2021-08-31 11:00:00'),
       (21, 27, '2021-08-31 11:00:00'),
       (21, 28, '2021-08-31 11:00:00'),
       (21, 29, '2021-08-31 11:00:00'),
       (21, 30, '2021-08-31 11:00:00'),
       (21, 31, '2021-08-31 11:00:00'),
       (21, 33, '2021-08-31 11:00:00'),
       (21, 34, '2021-08-31 11:00:00'),
       (22, 19, '2021-08-31 11:00:00'),
       (22, 21, '2021-08-31 11:00:00'),
       (22, 23, '2021-08-31 11:00:00'),
       (22, 25, '2021-08-31 11:00:00'),
       (22, 26, '2021-08-31 11:00:00'),
       (22, 27, '2021-08-31 11:00:00'),
       (22, 28, '2021-08-31 11:00:00'),
       (22, 29, '2021-08-31 11:00:00'),
       (22, 30, '2021-08-31 11:00:00'),
       (22, 32, '2021-08-31 11:00:00'),
       (22, 33, '2021-08-31 11:00:00'),
       (22, 34, '2021-08-31 11:00:00'),
       (23, 18, '2021-08-31 11:00:00'),
       (23, 20, '2021-08-31 11:00:00'),
       (23, 22, '2021-08-31 11:00:00'),
       (23, 24, '2021-08-31 11:00:00'),
       (23, 26, '2021-08-31 11:00:00'),
       (23, 27, '2021-08-31 11:00:00'),
       (23, 28, '2021-08-31 11:00:00'),
       (23, 29, '2021-08-31 11:00:00'),
       (23, 30, '2021-08-31 11:00:00'),
       (23, 31, '2021-08-31 11:00:00'),
       (23, 33, '2021-08-31 11:00:00'),
       (23, 34, '2021-08-31 11:00:00'),
       (24, 19, '2021-08-31 11:00:00'),
       (24, 21, '2021-08-31 11:00:00'),
       (24, 23, '2021-08-31 11:00:00'),
       (24, 25, '2021-08-31 11:00:00'),
       (24, 26, '2021-08-31 11:00:00'),
       (24, 27, '2021-08-31 11:00:00'),
       (24, 28, '2021-08-31 11:00:00'),
       (24, 29, '2021-08-31 11:00:00'),
       (24, 30, '2021-08-31 11:00:00'),
       (24, 32, '2021-08-31 11:00:00'),
       (24, 33, '2021-08-31 11:00:00'),
       (24, 34, '2021-08-31 11:00:00'),
       (25, 18, '2021-08-31 11:00:00'),
       (25, 20, '2021-08-31 11:00:00'),
       (25, 22, '2021-08-31 11:00:00'),
       (25, 24, '2021-08-31 11:00:00'),
       (25, 26, '2021-08-31 11:00:00'),
       (25, 27, '2021-08-31 11:00:00'),
       (25, 28, '2021-08-31 11:00:00'),
       (25, 29, '2021-08-31 11:00:00'),
       (25, 30, '2021-08-31 11:00:00'),
       (25, 31, '2021-08-31 11:00:00'),
       (25, 33, '2021-08-31 11:00:00'),
       (25, 34, '2021-08-31 11:00:00'),
       (26, 19, '2021-08-31 11:00:00'),
       (26, 21, '2021-08-31 11:00:00'),
       (26, 23, '2021-08-31 11:00:00'),
       (26, 25, '2021-08-31 11:00:00'),
       (26, 26, '2021-08-31 11:00:00'),
       (26, 27, '2021-08-31 11:00:00'),
       (26, 28, '2021-08-31 11:00:00'),
       (26, 29, '2021-08-31 11:00:00'),
       (26, 30, '2021-08-31 11:00:00'),
       (26, 32, '2021-08-31 11:00:00'),
       (26, 33, '2021-08-31 11:00:00'),
       (26, 34, '2021-08-31 11:00:00'),
       (27, 18, '2021-08-31 11:00:00'),
       (27, 20, '2021-08-31 11:00:00'),
       (27, 22, '2021-08-31 11:00:00'),
       (27, 24, '2021-08-31 11:00:00'),
       (27, 26, '2021-08-31 11:00:00'),
       (27, 27, '2021-08-31 11:00:00'),
       (27, 28, '2021-08-31 11:00:00'),
       (27, 29, '2021-08-31 11:00:00'),
       (27, 30, '2021-08-31 11:00:00'),
       (27, 31, '2021-08-31 11:00:00'),
       (27, 33, '2021-08-31 11:00:00'),
       (27, 34, '2021-08-31 11:00:00'),
       (28, 19, '2021-08-31 11:00:00'),
       (28, 21, '2021-08-31 11:00:00'),
       (28, 23, '2021-08-31 11:00:00'),
       (28, 25, '2021-08-31 11:00:00'),
       (28, 26, '2021-08-31 11:00:00'),
       (28, 27, '2021-08-31 11:00:00'),
       (28, 28, '2021-08-31 11:00:00'),
       (28, 29, '2021-08-31 11:00:00'),
       (28, 30, '2021-08-31 11:00:00'),
       (28, 32, '2021-08-31 11:00:00'),
       (28, 33, '2021-08-31 11:00:00'),
       (28, 34, '2021-08-31 11:00:00'),
       (29, 18, '2021-08-31 11:00:00'),
       (29, 20, '2021-08-31 11:00:00'),
       (29, 22, '2021-08-31 11:00:00'),
       (29, 24, '2021-08-31 11:00:00'),
       (29, 26, '2021-08-31 11:00:00'),
       (29, 27, '2021-08-31 11:00:00'),
       (29, 28, '2021-08-31 11:00:00'),
       (29, 29, '2021-08-31 11:00:00'),
       (29, 30, '2021-08-31 11:00:00'),
       (29, 31, '2021-08-31 11:00:00'),
       (29, 33, '2021-08-31 11:00:00'),
       (29, 34, '2021-08-31 11:00:00'),
       (30, 19, '2021-08-31 11:00:00'),
       (30, 21, '2021-08-31 11:00:00'),
       (30, 23, '2021-08-31 11:00:00'),
       (30, 25, '2021-08-31 11:00:00'),
       (30, 26, '2021-08-31 11:00:00'),
       (30, 27, '2021-08-31 11:00:00'),
       (30, 28, '2021-08-31 11:00:00'),
       (30, 29, '2021-08-31 11:00:00'),
       (30, 30, '2021-08-31 11:00:00'),
       (30, 32, '2021-08-31 11:00:00'),
       (30, 33, '2021-08-31 11:00:00'),
       (30, 34, '2021-08-31 11:00:00'),
       (31, 18, '2021-08-31 11:00:00'),
       (31, 20, '2021-08-31 11:00:00'),
       (31, 22, '2021-08-31 11:00:00'),
       (31, 24, '2021-08-31 11:00:00'),
       (31, 26, '2021-08-31 11:00:00'),
       (31, 27, '2021-08-31 11:00:00'),
       (31, 28, '2021-08-31 11:00:00'),
       (31, 29, '2021-08-31 11:00:00'),
       (31, 30, '2021-08-31 11:00:00'),
       (31, 31, '2021-08-31 11:00:00'),
       (31, 33, '2021-08-31 11:00:00'),
       (31, 34, '2021-08-31 11:00:00'),
       (32, 19, '2021-08-31 11:00:00'),
       (32, 21, '2021-08-31 11:00:00'),
       (32, 23, '2021-08-31 11:00:00'),
       (32, 25, '2021-08-31 11:00:00'),
       (32, 26, '2021-08-31 11:00:00'),
       (32, 27, '2021-08-31 11:00:00'),
       (32, 28, '2021-08-31 11:00:00'),
       (32, 29, '2021-08-31 11:00:00'),
       (32, 30, '2021-08-31 11:00:00'),
       (32, 32, '2021-08-31 11:00:00'),
       (32, 33, '2021-08-31 11:00:00'),
       (32, 34, '2021-08-31 11:00:00'),
       (33, 18, '2021-08-31 11:00:00'),
       (33, 20, '2021-08-31 11:00:00'),
       (33, 22, '2021-08-31 11:00:00'),
       (33, 24, '2021-08-31 11:00:00'),
       (33, 26, '2021-08-31 11:00:00'),
       (33, 27, '2021-08-31 11:00:00'),
       (33, 28, '2021-08-31 11:00:00'),
       (33, 29, '2021-08-31 11:00:00'),
       (33, 30, '2021-08-31 11:00:00'),
       (33, 31, '2021-08-31 11:00:00'),
       (33, 33, '2021-08-31 11:00:00'),
       (33, 34, '2021-08-31 11:00:00'),
       (34, 19, '2021-08-31 11:00:00'),
       (34, 21, '2021-08-31 11:00:00'),
       (34, 23, '2021-08-31 11:00:00'),
       (34, 25, '2021-08-31 11:00:00'),
       (34, 26, '2021-08-31 11:00:00'),
       (34, 27, '2021-08-31 11:00:00'),
       (34, 28, '2021-08-31 11:00:00'),
       (34, 29, '2021-08-31 11:00:00'),
       (34, 30, '2021-08-31 11:00:00'),
       (34, 32, '2021-08-31 11:00:00'),
       (34, 33, '2021-08-31 11:00:00'),
       (34, 34, '2021-08-31 11:00:00'),
       (35, 18, '2021-08-31 11:00:00'),
       (35, 20, '2021-08-31 11:00:00'),
       (35, 22, '2021-08-31 11:00:00'),
       (35, 24, '2021-08-31 11:00:00'),
       (35, 26, '2021-08-31 11:00:00'),
       (35, 27, '2021-08-31 11:00:00'),
       (35, 28, '2021-08-31 11:00:00'),
       (35, 29, '2021-08-31 11:00:00'),
       (35, 30, '2021-08-31 11:00:00'),
       (35, 31, '2021-08-31 11:00:00'),
       (35, 33, '2021-08-31 11:00:00'),
       (35, 34, '2021-08-31 11:00:00'),
       (36, 19, '2021-08-31 11:00:00'),
       (36, 21, '2021-08-31 11:00:00'),
       (36, 23, '2021-08-31 11:00:00'),
       (36, 25, '2021-08-31 11:00:00'),
       (36, 26, '2021-08-31 11:00:00'),
       (36, 27, '2021-08-31 11:00:00'),
       (36, 28, '2021-08-31 11:00:00'),
       (36, 29, '2021-08-31 11:00:00'),
       (36, 30, '2021-08-31 11:00:00'),
       (36, 32, '2021-08-31 11:00:00'),
       (36, 33, '2021-08-31 11:00:00'),
       (36, 34, '2021-08-31 11:00:00'),
       (37, 18, '2021-08-31 11:00:00'),
       (37, 20, '2021-08-31 11:00:00'),
       (37, 22, '2021-08-31 11:00:00'),
       (37, 24, '2021-08-31 11:00:00'),
       (37, 26, '2021-08-31 11:00:00'),
       (37, 27, '2021-08-31 11:00:00'),
       (37, 28, '2021-08-31 11:00:00'),
       (37, 29, '2021-08-31 11:00:00'),
       (37, 30, '2021-08-31 11:00:00'),
       (37, 31, '2021-08-31 11:00:00'),
       (37, 33, '2021-08-31 11:00:00'),
       (37, 34, '2021-08-31 11:00:00'),
       (38, 19, '2021-08-31 11:00:00'),
       (38, 21, '2021-08-31 11:00:00'),
       (38, 23, '2021-08-31 11:00:00'),
       (38, 25, '2021-08-31 11:00:00'),
       (38, 26, '2021-08-31 11:00:00'),
       (38, 27, '2021-08-31 11:00:00'),
       (38, 28, '2021-08-31 11:00:00'),
       (38, 29, '2021-08-31 11:00:00'),
       (38, 30, '2021-08-31 11:00:00'),
       (38, 32, '2021-08-31 11:00:00'),
       (38, 33, '2021-08-31 11:00:00'),
       (38, 34, '2021-08-31 11:00:00'),
       (39, 18, '2021-08-31 11:00:00'),
       (39, 20, '2021-08-31 11:00:00'),
       (39, 22, '2021-08-31 11:00:00'),
       (39, 24, '2021-08-31 11:00:00'),
       (39, 26, '2021-08-31 11:00:00'),
       (39, 27, '2021-08-31 11:00:00'),
       (39, 28, '2021-08-31 11:00:00'),
       (39, 29, '2021-08-31 11:00:00'),
       (39, 30, '2021-08-31 11:00:00'),
       (39, 31, '2021-08-31 11:00:00'),
       (39, 33, '2021-08-31 11:00:00'),
       (39, 34, '2021-08-31 11:00:00'),
       (40, 19, '2021-08-31 11:00:00'),
       (40, 21, '2021-08-31 11:00:00'),
       (40, 23, '2021-08-31 11:00:00'),
       (40, 25, '2021-08-31 11:00:00'),
       (40, 26, '2021-08-31 11:00:00'),
       (40, 27, '2021-08-31 11:00:00'),
       (40, 28, '2021-08-31 11:00:00'),
       (40, 29, '2021-08-31 11:00:00'),
       (40, 30, '2021-08-31 11:00:00'),
       (40, 32, '2021-08-31 11:00:00'),
       (40, 33, '2021-08-31 11:00:00'),
       (40, 34, '2021-08-31 11:00:00'),
       (41, 35, '2021-08-31 11:00:00'),
       (41, 37, '2021-08-31 11:00:00'),
       (41, 39, '2021-08-31 11:00:00'),
       (41, 41, '2021-08-31 11:00:00'),
       (41, 43, '2021-08-31 11:00:00'),
       (41, 44, '2021-08-31 11:00:00'),
       (41, 45, '2021-08-31 11:00:00'),
       (41, 46, '2021-08-31 11:00:00'),
       (41, 47, '2021-08-31 11:00:00'),
       (41, 48, '2021-08-31 11:00:00'),
       (41, 50, '2021-08-31 11:00:00'),
       (41, 51, '2021-08-31 11:00:00'),
       (42, 36, '2021-08-31 11:00:00'),
       (42, 38, '2021-08-31 11:00:00'),
       (42, 40, '2021-08-31 11:00:00'),
       (42, 42, '2021-08-31 11:00:00'),
       (42, 43, '2021-08-31 11:00:00'),
       (42, 44, '2021-08-31 11:00:00'),
       (42, 45, '2021-08-31 11:00:00'),
       (42, 46, '2021-08-31 11:00:00'),
       (42, 47, '2021-08-31 11:00:00'),
       (42, 49, '2021-08-31 11:00:00'),
       (42, 50, '2021-08-31 11:00:00'),
       (42, 51, '2021-08-31 11:00:00'),
       (43, 35, '2021-08-31 11:00:00'),
       (43, 37, '2021-08-31 11:00:00'),
       (43, 39, '2021-08-31 11:00:00'),
       (43, 41, '2021-08-31 11:00:00'),
       (43, 43, '2021-08-31 11:00:00'),
       (43, 44, '2021-08-31 11:00:00'),
       (43, 45, '2021-08-31 11:00:00'),
       (43, 46, '2021-08-31 11:00:00'),
       (43, 47, '2021-08-31 11:00:00'),
       (43, 48, '2021-08-31 11:00:00'),
       (43, 50, '2021-08-31 11:00:00'),
       (43, 51, '2021-08-31 11:00:00'),
       (44, 36, '2021-08-31 11:00:00'),
       (44, 38, '2021-08-31 11:00:00'),
       (44, 40, '2021-08-31 11:00:00'),
       (44, 42, '2021-08-31 11:00:00'),
       (44, 43, '2021-08-31 11:00:00'),
       (44, 44, '2021-08-31 11:00:00'),
       (44, 45, '2021-08-31 11:00:00'),
       (44, 46, '2021-08-31 11:00:00'),
       (44, 47, '2021-08-31 11:00:00'),
       (44, 49, '2021-08-31 11:00:00'),
       (44, 50, '2021-08-31 11:00:00'),
       (44, 51, '2021-08-31 11:00:00'),
       (45, 35, '2021-08-31 11:00:00'),
       (45, 37, '2021-08-31 11:00:00'),
       (45, 39, '2021-08-31 11:00:00'),
       (45, 41, '2021-08-31 11:00:00'),
       (45, 43, '2021-08-31 11:00:00'),
       (45, 44, '2021-08-31 11:00:00'),
       (45, 45, '2021-08-31 11:00:00'),
       (45, 46, '2021-08-31 11:00:00'),
       (45, 47, '2021-08-31 11:00:00'),
       (45, 48, '2021-08-31 11:00:00'),
       (45, 50, '2021-08-31 11:00:00'),
       (45, 51, '2021-08-31 11:00:00'),
       (46, 36, '2021-08-31 11:00:00'),
       (46, 38, '2021-08-31 11:00:00'),
       (46, 40, '2021-08-31 11:00:00'),
       (46, 42, '2021-08-31 11:00:00'),
       (46, 43, '2021-08-31 11:00:00'),
       (46, 44, '2021-08-31 11:00:00'),
       (46, 45, '2021-08-31 11:00:00'),
       (46, 46, '2021-08-31 11:00:00'),
       (46, 47, '2021-08-31 11:00:00'),
       (46, 49, '2021-08-31 11:00:00'),
       (46, 50, '2021-08-31 11:00:00'),
       (46, 51, '2021-08-31 11:00:00'),
       (47, 35, '2021-08-31 11:00:00'),
       (47, 37, '2021-08-31 11:00:00'),
       (47, 39, '2021-08-31 11:00:00'),
       (47, 41, '2021-08-31 11:00:00'),
       (47, 43, '2021-08-31 11:00:00'),
       (47, 44, '2021-08-31 11:00:00'),
       (47, 45, '2021-08-31 11:00:00'),
       (47, 46, '2021-08-31 11:00:00'),
       (47, 47, '2021-08-31 11:00:00'),
       (47, 48, '2021-08-31 11:00:00'),
       (47, 50, '2021-08-31 11:00:00'),
       (47, 51, '2021-08-31 11:00:00'),
       (48, 36, '2021-08-31 11:00:00'),
       (48, 38, '2021-08-31 11:00:00'),
       (48, 40, '2021-08-31 11:00:00'),
       (48, 42, '2021-08-31 11:00:00'),
       (48, 43, '2021-08-31 11:00:00'),
       (48, 44, '2021-08-31 11:00:00'),
       (48, 45, '2021-08-31 11:00:00'),
       (48, 46, '2021-08-31 11:00:00'),
       (48, 47, '2021-08-31 11:00:00'),
       (48, 49, '2021-08-31 11:00:00'),
       (48, 50, '2021-08-31 11:00:00'),
       (48, 51, '2021-08-31 11:00:00'),
       (49, 35, '2021-08-31 11:00:00'),
       (49, 37, '2021-08-31 11:00:00'),
       (49, 39, '2021-08-31 11:00:00'),
       (49, 41, '2021-08-31 11:00:00'),
       (49, 43, '2021-08-31 11:00:00'),
       (49, 44, '2021-08-31 11:00:00'),
       (49, 45, '2021-08-31 11:00:00'),
       (49, 46, '2021-08-31 11:00:00'),
       (49, 47, '2021-08-31 11:00:00'),
       (49, 48, '2021-08-31 11:00:00'),
       (49, 50, '2021-08-31 11:00:00'),
       (49, 51, '2021-08-31 11:00:00'),
       (50, 36, '2021-08-31 11:00:00'),
       (50, 38, '2021-08-31 11:00:00'),
       (50, 40, '2021-08-31 11:00:00'),
       (50, 42, '2021-08-31 11:00:00'),
       (50, 43, '2021-08-31 11:00:00'),
       (50, 44, '2021-08-31 11:00:00'),
       (50, 45, '2021-08-31 11:00:00'),
       (50, 46, '2021-08-31 11:00:00'),
       (50, 47, '2021-08-31 11:00:00'),
       (50, 49, '2021-08-31 11:00:00'),
       (50, 50, '2021-08-31 11:00:00'),
       (50, 51, '2021-08-31 11:00:00'),
       (51, 35, '2021-08-31 11:00:00'),
       (51, 37, '2021-08-31 11:00:00'),
       (51, 39, '2021-08-31 11:00:00'),
       (51, 41, '2021-08-31 11:00:00'),
       (51, 43, '2021-08-31 11:00:00'),
       (51, 44, '2021-08-31 11:00:00'),
       (51, 45, '2021-08-31 11:00:00'),
       (51, 46, '2021-08-31 11:00:00'),
       (51, 47, '2021-08-31 11:00:00'),
       (51, 48, '2021-08-31 11:00:00'),
       (51, 50, '2021-08-31 11:00:00'),
       (51, 51, '2021-08-31 11:00:00'),
       (52, 36, '2021-08-31 11:00:00'),
       (52, 38, '2021-08-31 11:00:00'),
       (52, 40, '2021-08-31 11:00:00'),
       (52, 42, '2021-08-31 11:00:00'),
       (52, 43, '2021-08-31 11:00:00'),
       (52, 44, '2021-08-31 11:00:00'),
       (52, 45, '2021-08-31 11:00:00'),
       (52, 46, '2021-08-31 11:00:00'),
       (52, 47, '2021-08-31 11:00:00'),
       (52, 49, '2021-08-31 11:00:00'),
       (52, 50, '2021-08-31 11:00:00'),
       (52, 51, '2021-08-31 11:00:00'),
       (53, 35, '2021-08-31 11:00:00'),
       (53, 37, '2021-08-31 11:00:00'),
       (53, 39, '2021-08-31 11:00:00'),
       (53, 41, '2021-08-31 11:00:00'),
       (53, 43, '2021-08-31 11:00:00'),
       (53, 44, '2021-08-31 11:00:00'),
       (53, 45, '2021-08-31 11:00:00'),
       (53, 46, '2021-08-31 11:00:00'),
       (53, 47, '2021-08-31 11:00:00'),
       (53, 48, '2021-08-31 11:00:00'),
       (53, 50, '2021-08-31 11:00:00'),
       (53, 51, '2021-08-31 11:00:00'),
       (54, 36, '2021-08-31 11:00:00'),
       (54, 38, '2021-08-31 11:00:00'),
       (54, 40, '2021-08-31 11:00:00'),
       (54, 42, '2021-08-31 11:00:00'),
       (54, 43, '2021-08-31 11:00:00'),
       (54, 44, '2021-08-31 11:00:00'),
       (54, 45, '2021-08-31 11:00:00'),
       (54, 46, '2021-08-31 11:00:00'),
       (54, 47, '2021-08-31 11:00:00'),
       (54, 49, '2021-08-31 11:00:00'),
       (54, 50, '2021-08-31 11:00:00'),
       (54, 51, '2021-08-31 11:00:00'),
       (55, 35, '2021-08-31 11:00:00'),
       (55, 37, '2021-08-31 11:00:00'),
       (55, 39, '2021-08-31 11:00:00'),
       (55, 41, '2021-08-31 11:00:00'),
       (55, 43, '2021-08-31 11:00:00'),
       (55, 44, '2021-08-31 11:00:00'),
       (55, 45, '2021-08-31 11:00:00'),
       (55, 46, '2021-08-31 11:00:00'),
       (55, 47, '2021-08-31 11:00:00'),
       (55, 48, '2021-08-31 11:00:00'),
       (55, 50, '2021-08-31 11:00:00'),
       (55, 51, '2021-08-31 11:00:00'),
       (56, 36, '2021-08-31 11:00:00'),
       (56, 38, '2021-08-31 11:00:00'),
       (56, 40, '2021-08-31 11:00:00'),
       (56, 42, '2021-08-31 11:00:00'),
       (56, 43, '2021-08-31 11:00:00'),
       (56, 44, '2021-08-31 11:00:00'),
       (56, 45, '2021-08-31 11:00:00'),
       (56, 46, '2021-08-31 11:00:00'),
       (56, 47, '2021-08-31 11:00:00'),
       (56, 49, '2021-08-31 11:00:00'),
       (56, 50, '2021-08-31 11:00:00'),
       (56, 51, '2021-08-31 11:00:00'),
       (57, 35, '2021-08-31 11:00:00'),
       (57, 37, '2021-08-31 11:00:00'),
       (57, 39, '2021-08-31 11:00:00'),
       (57, 41, '2021-08-31 11:00:00'),
       (57, 43, '2021-08-31 11:00:00'),
       (57, 44, '2021-08-31 11:00:00'),
       (57, 45, '2021-08-31 11:00:00'),
       (57, 46, '2021-08-31 11:00:00'),
       (57, 47, '2021-08-31 11:00:00'),
       (57, 48, '2021-08-31 11:00:00'),
       (57, 50, '2021-08-31 11:00:00'),
       (57, 51, '2021-08-31 11:00:00'),
       (58, 36, '2021-08-31 11:00:00'),
       (58, 38, '2021-08-31 11:00:00'),
       (58, 40, '2021-08-31 11:00:00'),
       (58, 42, '2021-08-31 11:00:00'),
       (58, 43, '2021-08-31 11:00:00'),
       (58, 44, '2021-08-31 11:00:00'),
       (58, 45, '2021-08-31 11:00:00'),
       (58, 46, '2021-08-31 11:00:00'),
       (58, 47, '2021-08-31 11:00:00'),
       (58, 49, '2021-08-31 11:00:00'),
       (58, 50, '2021-08-31 11:00:00'),
       (58, 51, '2021-08-31 11:00:00'),
       (59, 35, '2021-08-31 11:00:00'),
       (59, 37, '2021-08-31 11:00:00'),
       (59, 39, '2021-08-31 11:00:00'),
       (59, 41, '2021-08-31 11:00:00'),
       (59, 43, '2021-08-31 11:00:00'),
       (59, 44, '2021-08-31 11:00:00'),
       (59, 45, '2021-08-31 11:00:00'),
       (59, 46, '2021-08-31 11:00:00'),
       (59, 47, '2021-08-31 11:00:00'),
       (59, 48, '2021-08-31 11:00:00'),
       (59, 50, '2021-08-31 11:00:00'),
       (59, 51, '2021-08-31 11:00:00'),
       (60, 36, '2021-08-31 11:00:00'),
       (60, 38, '2021-08-31 11:00:00'),
       (60, 40, '2021-08-31 11:00:00'),
       (60, 42, '2021-08-31 11:00:00'),
       (60, 43, '2021-08-31 11:00:00'),
       (60, 44, '2021-08-31 11:00:00'),
       (60, 45, '2021-08-31 11:00:00'),
       (60, 46, '2021-08-31 11:00:00'),
       (60, 47, '2021-08-31 11:00:00'),
       (60, 49, '2021-08-31 11:00:00'),
       (60, 50, '2021-08-31 11:00:00'),
       (60, 51, '2021-08-31 11:00:00');

insert into classes (title, study_year)
values ('A', 11),
       ('B', 11),
       ('C', 11),
       ('A', 10),
       ('B', 10),
       ('C', 10),
       ('A', 9),
       ('B', 9),
       ('C', 9),
       ('A', 8),
       ('B', 8),
       ('C', 8),
       ('A', 7),
       ('B', 7),
       ('C', 7),
       ('A', 6),
       ('B', 6),
       ('C', 6),
       ('A', 5),
       ('B', 5),
       ('C', 5);


insert into class_history (pupil_id, class_id, change_time)
values (1, 1, '2021-08-31 07:02:00'),
       (2, 1, '2021-08-31 07:02:00'),
       (3, 1, '2021-08-31 07:02:00'),
       (4, 1, '2021-08-31 07:02:00'),
       (5, 1, '2021-08-31 07:02:00'),
       (6, 1, '2021-08-31 07:02:00'),
       (7, 1, '2021-08-31 07:02:00'),
       (8, 1, '2021-08-31 07:02:00'),
       (9, 1, '2021-08-31 07:02:00'),
       (10, 1, '2021-08-31 07:02:00'),
       (11, 1, '2021-08-31 07:02:00'),
       (12, 1, '2021-08-31 07:02:00'),
       (13, 1, '2021-08-31 07:02:00'),
       (14, 1, '2021-08-31 07:02:00'),
       (15, 1, '2021-08-31 07:02:00'),
       (16, 1, '2021-08-31 07:02:00'),
       (17, 1, '2021-08-31 07:02:00'),
       (18, 1, '2021-08-31 07:02:00'),
       (19, 1, '2021-08-31 07:02:00'),
       (20, 1, '2021-08-31 07:02:00'),
       (21, 2, '2021-08-31 07:02:00'),
       (22, 2, '2021-08-31 07:02:00'),
       (23, 2, '2021-08-31 07:02:00'),
       (24, 2, '2021-08-31 07:02:00'),
       (25, 2, '2021-08-31 07:02:00'),
       (26, 2, '2021-08-31 07:02:00'),
       (27, 2, '2021-08-31 07:02:00'),
       (28, 2, '2021-08-31 07:02:00'),
       (29, 2, '2021-08-31 07:02:00'),
       (30, 2, '2021-08-31 07:02:00'),
       (31, 2, '2021-08-31 07:02:00'),
       (32, 2, '2021-08-31 07:02:00'),
       (33, 2, '2021-08-31 07:02:00'),
       (34, 2, '2021-08-31 07:02:00'),
       (35, 2, '2021-08-31 07:02:00'),
       (36, 2, '2021-08-31 07:02:00'),
       (37, 2, '2021-08-31 07:02:00'),
       (38, 2, '2021-08-31 07:02:00'),
       (39, 2, '2021-08-31 07:02:00'),
       (40, 2, '2021-08-31 07:02:00'),
       (41, 3, '2021-08-31 07:02:00'),
       (42, 3, '2021-08-31 07:02:00'),
       (43, 3, '2021-08-31 07:02:00'),
       (44, 3, '2021-08-31 07:02:00'),
       (45, 3, '2021-08-31 07:02:00'),
       (46, 3, '2021-08-31 07:02:00'),
       (47, 3, '2021-08-31 07:02:00'),
       (48, 3, '2021-08-31 07:02:00'),
       (49, 3, '2021-08-31 07:02:00'),
       (50, 3, '2021-08-31 07:02:00'),
       (51, 3, '2021-08-31 07:02:00'),
       (52, 3, '2021-08-31 07:02:00'),
       (53, 3, '2021-08-31 07:02:00'),
       (54, 3, '2021-08-31 07:02:00'),
       (55, 3, '2021-08-31 07:02:00'),
       (56, 3, '2021-08-31 07:02:00'),
       (57, 3, '2021-08-31 07:02:00'),
       (58, 3, '2021-08-31 07:02:00'),
       (59, 3, '2021-08-31 07:02:00'),
       (60, 3, '2021-08-31 07:02:00');

insert into employees (first_name, last_name)
values ('Payten', 'Fischer'),
       ('Reagan', 'Harrell'),
       ('Amelia', 'Murillo'),
       ('Tyson', 'Stuart'),
       ('June', 'Oneal'),
       ('Trey', 'Mckenzie'),
       ('Dezi', 'Mcbride'),
       ('Naveen', 'Cunningham'),
       ('Everett', 'Hooper'),
       ('Raine', 'Mills'),
       ('Kae', 'Lang'),
       ('Caprice', 'Burns'),
       ('Noel', 'Williamson'),
       ('Madisen', 'Mills'),
       ('Jae', 'Mcguire'),
       ('Blayne', 'Salazar'),
       ('Adele', 'Merritt'),
       ('Kalan', 'Garrison'),
       ('Clementine', 'Preston'),
       ('Porter', 'Dougherty'),
       ('Lee', 'Baird'),
       ('Bianca', 'Krueger'),
       ('Lynn', 'Taylor'),
       ('Aiden', 'Levine'),
       ('Rene', 'Pollard'),
       ('Wade', 'Watson'),
       ('Benjamin', 'Kemp'),
       ('Susannah', 'Moody'),
       ('Justin', 'Davenport'),
       ('Doran', 'Powers'),
       ('Elein', 'Durham'),
       ('Irene', 'Mccoy'),
       ('Nadeen', 'Wiggins'),
       ('Noah', 'Zhang'),
       ('Sutton', 'Mathis'),
       ('Madeleine', 'Riley'),
       ('Fernando', 'Murphy'),
       ('Tristan', 'Pham'),
       ('Dustin', 'Hayden'),
       ('Bailee', 'Nolan');

insert into posts (title)
values ('Director'),
       ('Head teacher'),
       ('Accountant'),
       ('Librarian'),
       ('Laboratory assistant'),
       ('Teacher');

insert into employees_history (employee_id, post_id, begin_time)
values (1, 1, '2021-09-01 10:00:00'),
       (2, 3, '2021-09-01 10:00:00'),
       (3, 4, '2021-09-01 10:00:00'),
       (4, 2, '2021-09-01 10:00:00'),
       (5, 2, '2021-09-01 10:00:00'),
       (6, 5, '2021-09-01 10:00:00'),
       (7, 6, '2021-08-31 09:30:00'),
       (8, 6, '2021-08-31 09:30:00'),
       (9, 6, '2021-08-31 09:30:00'),
       (10, 6, '2021-08-31 09:30:00'),
       (11, 6, '2021-08-31 09:30:00'),
       (12, 6, '2021-08-31 09:30:00'),
       (13, 6, '2021-08-31 09:30:00'),
       (14, 6, '2021-08-31 09:30:00'),
       (15, 6, '2021-08-31 09:30:00'),
       (16, 6, '2021-08-31 09:30:00'),
       (17, 6, '2021-08-31 09:30:00'),
       (18, 6, '2021-08-31 09:30:00'),
       (19, 6, '2021-08-31 09:30:00'),
       (20, 6, '2021-08-31 09:30:00'),
       (21, 6, '2021-08-31 09:30:00'),
       (22, 6, '2021-08-31 09:30:00'),
       (23, 6, '2021-08-31 09:30:00'),
       (24, 6, '2021-08-31 09:30:00'),
       (25, 6, '2021-08-31 09:30:00'),
       (26, 6, '2021-08-31 09:30:00'),
       (27, 6, '2021-08-31 09:30:00'),
       (28, 6, '2021-08-31 09:30:00'),
       (29, 6, '2021-08-31 09:30:00'),
       (30, 6, '2021-08-31 09:30:00'),
       (31, 6, '2021-08-31 09:30:00'),
       (32, 6, '2021-08-31 09:30:00'),
       (33, 6, '2021-08-31 09:30:00'),
       (34, 6, '2021-08-31 09:30:00'),
       (35, 6, '2021-08-31 09:30:00'),
       (36, 6, '2021-08-31 09:30:00'),
       (37, 6, '2021-08-31 09:30:00'),
       (38, 6, '2021-08-31 09:30:00'),
       (39, 6, '2021-08-31 09:30:00'),
       (40, 6, '2021-08-31 09:30:00');

insert into salary_history (salary, change_time, employee_id)
values (6041, '2021-09-01 10:00:00', 1),
       (3467, '2021-09-01 10:00:00', 2),
       (4634, '2021-09-01 10:00:00', 3),
       (5500, '2021-09-01 10:00:00', 4),
       (3469, '2021-09-01 10:00:00', 5),
       (4724, '2021-09-01 10:00:00', 6),
       (5478, '2021-09-01 10:00:00', 7),
       (5358, '2021-09-01 10:00:00', 8),
       (5962, '2021-09-01 10:00:00', 9),
       (3464, '2021-09-01 10:00:00', 10),
       (5705, '2021-09-01 10:00:00', 11),
       (4145, '2021-09-01 10:00:00', 12),
       (5281, '2021-09-01 10:00:00', 13),
       (4827, '2021-09-01 10:00:00', 14),
       (3961, '2021-09-01 10:00:00', 15),
       (3491, '2021-09-01 10:00:00', 16),
       (5995, '2021-09-01 10:00:00', 17),
       (5942, '2021-09-01 10:00:00', 18),
       (4827, '2021-09-01 10:00:00', 19),
       (5436, '2021-09-01 10:00:00', 20),
       (5391, '2021-09-01 10:00:00', 21),
       (5604, '2021-09-01 10:00:00', 22),
       (3902, '2021-09-01 10:00:00', 23),
       (3153, '2021-09-01 10:00:00', 24),
       (3292, '2021-09-01 10:00:00', 25),
       (3382, '2021-09-01 10:00:00', 26),
       (5421, '2021-09-01 10:00:00', 27),
       (3716, '2021-09-01 10:00:00', 28),
       (4718, '2021-09-01 10:00:00', 29),
       (4895, '2021-09-01 10:00:00', 30),
       (5447, '2021-09-01 10:00:00', 31),
       (3726, '2021-09-01 10:00:00', 32),
       (5771, '2021-09-01 10:00:00', 33),
       (5538, '2021-09-01 10:00:00', 34),
       (4869, '2021-09-01 10:00:00', 35),
       (4912, '2021-09-01 10:00:00', 36),
       (4667, '2021-09-01 10:00:00', 37),
       (5299, '2021-09-01 10:00:00', 38),
       (5035, '2021-09-01 10:00:00', 39),
       (3894, '2021-09-01 10:00:00', 40);

insert into class_teacher_history (class_id, teacher_id, change_time)
values (1, 40, '2021-09-01 11:00:00'),
       (2, 39, '2021-09-01 11:00:00'),
       (3, 38, '2021-09-01 11:00:00'),
       (4, 37, '2021-09-01 11:00:00'),
       (5, 36, '2021-09-01 11:00:00'),
       (6, 35, '2021-09-01 11:00:00'),
       (7, 34, '2021-09-01 11:00:00'),
       (8, 33, '2021-09-01 11:00:00'),
       (9, 32, '2021-09-01 11:00:00'),
       (10, 31, '2021-09-01 11:00:00'),
       (11, 30, '2021-09-01 11:00:00'),
       (12, 29, '2021-09-01 11:00:00'),
       (13, 28, '2021-09-01 11:00:00'),
       (14, 27, '2021-09-01 11:00:00'),
       (15, 26, '2021-09-01 11:00:00'),
       (16, 25, '2021-09-01 11:00:00'),
       (17, 24, '2021-09-01 11:00:00'),
       (18, 23, '2021-09-01 11:00:00'),
       (19, 22, '2021-09-01 11:00:00'),
       (20, 21, '2021-09-01 11:00:00'),
       (21, 20, '2021-09-01 11:00:00');

insert into rooms (title, room_type, seats)
values ('101a', 'common', 23),
       ('101b', 'common', 14),
       ('102a', 'common', 16),
       ('102b', 'common', 22),
       ('103a', 'common', 26),
       ('103b', 'common', 16),
       ('104a', 'common', 15),
       ('104b', 'common', 15),
       ('105a', 'common', 19),
       ('105b', 'common', 26),
       ('106a', 'common', 17),
       ('106b', 'common', 17),
       ('107a', 'common', 13),
       ('107b', 'common', 24),
       ('108a', 'common', 13),
       ('108b', 'common', 23),
       ('109a', 'common', 22),
       ('109b', 'common', 14),
       ('110a', 'common', 24),
       ('110b', 'common', 18),
       ('111a', 'common', 18),
       ('111b', 'common', 21),
       ('112a', 'common', 14),
       ('112b', 'common', 15),
       ('113a', 'common', 19),
       ('113b', 'common', 19),
       ('114a', 'common', 18),
       ('114b', 'common', 23),
       ('115a', 'common', 20),
       ('115b', 'common', 17),
       ('201a', 'common', 14),
       ('201b', 'common', 18),
       ('202a', 'common', 23),
       ('202b', 'common', 15),
       ('203a', 'common', 21),
       ('203b', 'common', 19),
       ('204a', 'common', 14),
       ('204b', 'common', 16),
       ('205a', 'common', 22),
       ('205b', 'common', 21),
       ('206a', 'common', 20),
       ('206b', 'common', 18),
       ('207a', 'common', 14),
       ('207b', 'common', 15),
       ('208a', 'common', 15),
       ('208b', 'common', 26),
       ('209a', 'common', 18),
       ('209b', 'common', 13),
       ('210a', 'common', 20),
       ('210b', 'common', 25),
       ('211a', 'common', 14),
       ('211b', 'common', 26),
       ('212a', 'common', 19),
       ('212b', 'common', 24),
       ('213a', 'common', 24),
       ('213b', 'common', 16),
       ('214a', 'common', 20),
       ('214b', 'common', 18),
       ('215a', 'common', 16),
       ('215b', 'common', 25),
       ('301a', 'common', 13),
       ('301b', 'common', 17),
       ('302a', 'common', 17),
       ('302b', 'common', 24),
       ('303a', 'common', 15),
       ('303b', 'common', 13),
       ('304a', 'common', 22),
       ('304b', 'common', 14),
       ('305a', 'common', 16),
       ('305b', 'common', 25),
       ('306a', 'common', 23),
       ('306b', 'common', 12),
       ('307a', 'common', 17),
       ('307b', 'common', 21),
       ('308a', 'common', 22),
       ('308b', 'common', 17),
       ('309a', 'common', 18),
       ('309b', 'common', 18),
       ('310a', 'common', 15),
       ('310b', 'common', 20),
       ('311a', 'common', 21),
       ('311b', 'common', 20),
       ('312a', 'common', 21),
       ('312b', 'common', 16),
       ('313a', 'common', 18),
       ('313b', 'common', 17),
       ('314a', 'common', 13),
       ('314b', 'common', 23),
       ('315a', 'common', 23),
       ('315b', 'common', 25);


insert into schedule_history (teacher_id, room_id, bell_order, subject_id, week_day, is_odd_week)
values (2, 2, 1, 1, 'Thursday', True),
       (2, 2, 1, 2, 'Thursday', False),
       (1, 4, 1, 1, 'Thursday', False),
       (3, 2, 2, 2, 'Thursday', True),
       (2, 3, 2, 2, 'Thursday', True);

insert into events (room_id, teacher_id, theme_id, event_bell)
values (3, 2, 1, 1),
       (2, 3, 3, 2),
       (3, 1, 3, 2);

--data final block end


