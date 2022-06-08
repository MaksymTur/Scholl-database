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
    title      varchar(30) NOT NULL,
    subject_id serial,
    mandatory  boolean     NOT NULL,

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
    begin_time  time,
    end_time    time,
    change_date date DEFAULT now() NOT NULL,
    change_id   serial,

    PRIMARY KEY (change_id)
);


CREATE TABLE classes
(
    title      varchar(10) NOT NULL,
    study_year int         NOT NULL,
    class_id   serial,

    PRIMARY KEY (class_id)
);

CREATE TABLE "groups"
(
    title      varchar(40) NOT NULL,
    class_id   integer REFERENCES classes,
    subject_id integer REFERENCES subjects,
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
    class_id            integer REFERENCES classes,
    is_odd_week         bool,
    "week_day"          week_day                     NOT NULL,
    bell_order          integer                      NOT NULL,
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
    class_id   integer REFERENCES classes,
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

CREATE TABLE skips
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


CREATE TABLE subject_to_class_certificate
(
    class_id   int REFERENCES classes  NOT NULL,
    subject_id int REFERENCES subjects NOT NULL,

    PRIMARY KEY (class_id, subject_id)
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
                        WHERE change_date <= bell_date
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
                        WHERE change_date <= bell_date
                          AND bell_schedule_history.bell_order = bell_end_time.bell_order
                        ORDER BY change_date DESC
                        LIMIT 1);
end
$$ language plpgsql;

CREATE FUNCTION bell_begin_time(bell_order int)
    RETURNS timestamp AS
$$
begin
    return bell_begin_time(now()::date, bell_order);
end
$$ language plpgsql;

CREATE FUNCTION bell_end_time(bell_order int)
    RETURNS timestamp AS
$$
begin
    return bell_end_time(now()::date, bell_order);
end
$$ language plpgsql;

CREATE FUNCTION was_at_lecture(pupil_id int, event_id int)
    RETURNS boolean AS
$$
begin
    return (NOT EXISTS((SELECT skips.pupil_id
                        FROM skips
                        WHERE skips.pupil_id = was_at_lecture.pupil_id
                          AND skips.event_id = was_at_lecture.event_id)));
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

CREATE FUNCTION get_class(pupil_id int, at_time timestamp)
    RETURNS integer AS
$$
begin
    return (SELECT class_history.class_id
            FROM class_history
            WHERE class_history.pupil_id = get_class.pupil_id
              AND class_history.change_time <= get_class.at_time
            ORDER BY change_time DESC
            LIMIT 1);
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
         WHERE sch.bell_order = add_bell.bell_order)::time <= change_time::time) then
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

CREATE FUNCTION get_pupils_from_group(group_id1 integer, at_time timestamp DEFAULT now())
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
                    AND (end_time > at_time OR end_time IS NULL)
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
              FROM marks
                       NATURAL JOIN events
                       NATURAL JOIN type_weights_history
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

CREATE FUNCTION get_group_class(group_id integer)
    RETURNS integer
AS
$$
begin
    return (SELECT class_id FROM "groups" WHERE get_group_class.group_id = groups.group_id);
end;
$$ language plpgsql;

CREATE FUNCTION get_subject_of_theme(theme_id integer)
    RETURNS integer
AS
$$
begin
    return (SELECT subject_id FROM themes WHERE themes.theme_id = get_subject_of_theme.theme_id);
end;
$$ language plpgsql;

CREATE FUNCTION get_mandatory(subject_id integer)
    RETURNS boolean
AS
$$
begin
    return (SELECT mandatory
                 FROM subjects
                 WHERE subjects.subject_id = get_mandatory.subject_id);
end;
$$ language plpgsql;

CREATE FUNCTION get_theme_of_event(event_id integer)
    RETURNS boolean
AS
$$
begin
    return (SELECT get_theme_of_event(theme_id)
                 FROM events
                 WHERE events.event_id = get_theme_of_event.event_id);
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
    for bell_order, begin_time, end_time in (SELECT * FROM get_bells_schedule(NEW.change_date::date))
        loop
            if (bell_order != NEW.bell_order AND
                NOT (NEW.begin_time > end_time::time OR begin_time::time > NEW.end_time)) then
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

CREATE FUNCTION groups_mandatory_check_f(class_id integer, subject_id integer)
    RETURNS boolean AS
$$
begin
    return (subject_id IS NULL
                OR (SELECT mandatory
                    FROM subjects
                    WHERE subjects.subject_id = groups_mandatory_check_f.subject_id) = False
                OR ((SELECT mandatory
                     FROM subjects
                     WHERE subjects.subject_id = groups_mandatory_check_f.subject_id) = True
                AND class_id IS NOT NULL));
end;
$$
    LANGUAGE PLPGSQL;

ALTER TABLE "groups"
    ADD CONSTRAINT groups_mandatory_check
        CHECK (  
               groups_mandatory_check_f(class_id, subject_id)
            );

ALTER TABLE groups_history
    ADD CONSTRAINT groups_history_add_before_deletion_check
        CHECK (
            begin_time < end_time
            );

CREATE FUNCTION groups_history_insert_trigger()
    RETURNS TRIGGER AS
$$
begin
    if (get_group_class(NEW.group_id) IS NULL) then
        return NEW;
    end if;
    if (get_group_class(NEW.group_id) != get_class(NEW.pupil_id, NEW.begin_time)) then
        raise exception 'Can not add pupil to group not of his class.';
    end if;
    return NEW;
end;
$$
    LANGUAGE PLPGSQL;

CREATE TRIGGER groups_history_appropriate_class_of_pupil
    BEFORE INSERT
    ON groups_history
    FOR EACH ROW
EXECUTE PROCEDURE groups_history_insert_trigger();

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

ALTER TABLE marks
    ADD CONSTRAINT marks_only_in_mandatory_subjects
        CHECK (
                get_mandatory(get_subject_of_theme(get_theme_of_event(event_id))) = True
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

CREATE FUNCTION class_history_insert_delete_from_groups_trigger()
    RETURNS TRIGGER AS
$$
declare
    i integer;
begin
    for i in (SELECT group_id
              FROM get_groups_of_pupil(NEW.pupil_id, change_time)
              WHERE get_group_class(group_id) IS NOT NULL
                AND get_group_class(group_id) != get_class(NEW.pupil_id, change_time))
        loop
            SELECT delete_from_group(NEW.pupil_id, i, NEW.change_time);
        end loop;
end;
$$
    LANGUAGE PLPGSQL;

CREATE TRIGGER class_history_delete_from_not_that_class_groups
    BEFORE INSERT
    ON class_history
    FOR EACH ROW
EXECUTE PROCEDURE class_history_insert_delete_from_groups_trigger();

ALTER TABLE class_teacher_history
    ADD CONSTRAINT class_teacher_history_class_teacher_only_at_work_time
        CHECK (
            is_working(teacher_id, change_time)
            );

CREATE FUNCTION skips_insert_trigger()
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

ALTER TABLE skips
    ADD CONSTRAINT skips_only_at_mandatory_events
        CHECK (
                get_mandatory(get_subject_of_theme(get_theme_of_event(event_id))) = True
            );

CREATE TRIGGER skips_pupil_from_group_on_event
    BEFORE INSERT
    ON skips
    FOR EACH ROW
EXECUTE PROCEDURE skips_insert_trigger();

CREATE FUNCTION groups_to_events_same_subject_check_f(group_id integer, event_id integer)
    RETURNS boolean AS
$$
begin
    return ((get_subject_of_theme((SELECT theme_id
                                    FROM events
                                    WHERE events.event_id = groups_to_events_same_subject_check_f.event_id)) =
              (SELECT subject_id
               FROM "groups"
               WHERE groups.group_id = groups_to_events_same_subject_check_f.group_id))
                OR (SELECT subject_id
                    FROM "groups"
                    WHERE groups.group_id = groups_to_events_same_subject_check_f.group_id) IS NULL);
end;
$$
    LANGUAGE PLPGSQL;

ALTER TABLE groups_to_events
    ADD CONSTRAINT groups_to_events_same_subject_check
        CHECK (
                groups_to_events_same_subject_check_f(group_id, event_id)
            );

CREATE FUNCTION groups_to_events_same_class_check_f(group_id integer, event_id integer)
    RETURNS boolean AS
$$
begin
    return (SELECT class_id
                 FROM events
                 WHERE events.event_id = groups_to_events_same_class_check_f.event_id) IS NULL
                OR (SELECT class_id
                    FROM events
                    WHERE events.event_id = groups_to_events_same_class_check_f.event_id) =
                   (SELECT class_id
                    FROM "groups"
                    WHERE groups.group_id = groups_to_events_same_class_check_f.group_id);
end;
$$
    LANGUAGE PLPGSQL;

ALTER TABLE groups_to_events
    ADD CONSTRAINT groups_to_events_same_class_check
        CHECK (
                groups_to_events_same_class_check_f(group_id, event_id)
            );

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
            FROM skips
            WHERE pupil_id = i
              AND skips.event_id = OLD.event_id;
        end loop;
    return OLD;
end;
$$
    LANGUAGE PLPGSQL;

ALTER TABLE subject_to_class_certificate
    ADD CONSTRAINT classes_normal_study_year_check
        CHECK (
                get_mandatory(subject_id) = True
            );

CREATE TRIGGER groups_to_events_delete_from_journal_on_delete
    BEFORE INSERT
    ON groups_to_events
    FOR EACH ROW
EXECUTE PROCEDURE groups_to_events_delete_trigger();

CREATE FUNCTION groups_to_schedule_same_subject_check_f(group_id integer, event_in_schedule_id integer)
    RETURNS boolean AS
$$
begin
    return ((SELECT subject_id
                  FROM schedule_history
                  WHERE schedule_history.schedule_history_id = groups_to_schedule_same_subject_check_f.event_in_schedule_id) =
                 (SELECT subject_id
                  FROM "groups"
                  WHERE groups.group_id = groups_to_schedule_same_subject_check_f.group_id))
                OR
                (SELECT subject_id
                 FROM "groups"
                 WHERE groups.group_id = groups_to_schedule_same_subject_check_f.group_id) IS NULL;
end;
$$
    LANGUAGE PLPGSQL;

ALTER TABLE groups_to_schedule
    ADD CONSTRAINT groups_to_schedule_same_subject_check
        CHECK (
                groups_to_schedule_same_subject_check_f(group_id, event_in_schedule_id)
         );

CREATE FUNCTION groups_to_schedule_same_class_check_f(group_id integer, event_in_schedule_id integer)
    RETURNS boolean AS
$$
begin
    return ((SELECT class_id
                  FROM schedule_history
                  WHERE schedule_history.schedule_history_id = groups_to_schedule_same_class_check_f.event_in_schedule_id) =
                 (SELECT class_id
                  FROM "groups"
                  WHERE groups.group_id = groups_to_schedule_same_class_check_f.group_id))
                OR
                (SELECT class_id
                 FROM "groups"
                 WHERE groups.group_id = groups_to_schedule_same_class_check_f.group_id) IS NULL;
end;
$$
    LANGUAGE PLPGSQL;

ALTER TABLE groups_to_schedule
    ADD CONSTRAINT groups_to_schedule_same_class_check
        CHECK (
                groups_to_schedule_same_class_check_f(group_id, event_in_schedule_id)
         );

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

insert into subjects (title, mandatory)
values ('Debate 11', false),
       ('Polish 11', true),
       ('English 11', true),
       ('Foreign language II 11', true),
       ('Mathematics 11', true),
       ('Biology 11', true),
       ('Chemistry 11', true),
       ('Physics 11', true),
       ('Geography 11', true),
       ('Informatics 11', true),
       ('History 11', true),
       ('Civics 11', true),
       ('Astronomy 11', true),
       ('Debate 10', false),
       ('Polish 10', true),
       ('English 10', true),
       ('Foreign language II 10', true),
       ('Mathematics 10', true),
       ('Biology 10', true),
       ('Chemistry 10', true),
       ('Physics 10', true),
       ('Geography 10', true),
       ('Informatics 10', true),
       ('History 10', true),
       ('Civics 10', true);

insert into pupils (date_of_birth, first_name, last_name)
values ('2005-08-26', 'Levi', 'Holland'),
       ('2005-07-01', 'Ellice', 'Fischer'),
       ('2005-07-27', 'Clelia', 'Stuart'),
       ('2005-08-26', 'Coralie', 'Cunningham'),
       ('2005-09-17', 'Randall', 'Lang'),
       ('2005-10-23', 'Elodie', 'Mills'),
       ('2005-11-09', 'Matilda', 'Garrison'),
       ('2005-12-03', 'Devon', 'Baird'),
       ('2005-12-27', 'Robert', 'Levine'),
       ('2005-07-07', 'June', 'Kemp'),
       ('2005-08-11', 'Sherleen', 'Durham'),
       ('2005-08-28', 'Caprice', 'Zhang'),
       ('2005-09-21', 'Leonie', 'Murphy'),
       ('2005-10-31', 'June', 'Nolan'),
       ('2005-11-14', 'Dustin', 'Baker'),
       ('2005-12-16', 'Lane', 'Ramsey'),
       ('2006-01-02', 'Vernon', 'Smith'),
       ('2005-07-23', 'Blaise', 'Pearson'),
       ('2005-08-25', 'Linnea', 'Young'),
       ('2005-09-13', 'Zane', 'Bright'),
       ('2005-07-23', 'Elijah', 'Murillo'),
       ('2005-08-25', 'Candice', 'Mcbride'),
       ('2005-09-13', 'Ellice', 'Mills'),
       ('2005-10-21', 'Sutton', 'Williamson'),
       ('2005-11-06', 'Jacklyn', 'Salazar'),
       ('2005-11-15', 'Cameron', 'Dougherty'),
       ('2005-12-19', 'Reeve', 'Taylor'),
       ('2005-07-01', 'Kai', 'Watson'),
       ('2005-07-27', 'Ellory', 'Davenport'),
       ('2005-08-26', 'Fawn', 'Wiggins'),
       ('2005-09-17', 'Gavin', 'Riley'),
       ('2005-10-23', 'Anise', 'Hayden'),
       ('2005-11-08', 'Blaise', 'Jacobs'),
       ('2005-12-03', 'Louisa', 'Buck'),
       ('2005-12-27', 'Tristan', 'Dunn'),
       ('2005-07-07', 'Brendon', 'Thompson'),
       ('2005-08-11', 'Evelyn', 'Young'),
       ('2005-08-28', 'Clark', 'Cain'),
       ('2005-07-07', 'Chase', 'Harrell'),
       ('2005-08-02', 'Aiden', 'Oneal'),
       ('2005-08-28', 'Timothy', 'Hooper'),
       ('2005-09-21', 'Dezi', 'Burns'),
       ('2005-10-31', 'Syllable', 'Mcguire'),
       ('2005-11-09', 'Matilda', 'Garrison'),
       ('2005-12-16', 'Jeremy', 'Krueger'),
       ('2006-01-02', 'Clelia', 'Pollard'),
       ('2005-07-23', 'Jackson', 'Moody'),
       ('2005-08-11', 'Sherleen', 'Durham'),
       ('2005-09-13', 'Lee', 'Mathis'),
       ('2005-10-21', 'Brighton', 'Pham'),
       ('2005-11-06', 'Raine', 'Watkins'),
       ('2005-11-14', 'Dustin', 'Baker'),
       ('2005-12-19', 'Juliet', 'Rollins'),
       ('2005-07-01', 'William', 'Baker'),
       ('2005-07-27', 'Chase', 'Rich'),
       ('2005-08-26', 'Levi', 'Holland'),
       ('2005-07-01', 'Ellice', 'Fischer'),
       ('2005-07-27', 'Clelia', 'Stuart'),
       ('2005-08-25', 'Candice', 'Mcbride'),
       ('2005-09-17', 'Randall', 'Lang'),
       ('2006-09-01', 'Levi', 'Holland'),
       ('2006-06-10', 'Ellice', 'Fischer'),
       ('2006-07-07', 'Clelia', 'Stuart'),
       ('2006-07-26', 'Coralie', 'Cunningham'),
       ('2006-08-26', 'Randall', 'Lang'),
       ('2006-09-12', 'Elodie', 'Mills'),
       ('2006-10-03', 'Matilda', 'Garrison'),
       ('2006-10-29', 'Devon', 'Baird'),
       ('2006-12-13', 'Robert', 'Levine'),
       ('2006-06-29', 'June', 'Kemp'),
       ('2006-07-16', 'Sherleen', 'Durham'),
       ('2006-07-23', 'Caprice', 'Zhang'),
       ('2006-10-16', 'Leonie', 'Murphy'),
       ('2006-11-26', 'June', 'Nolan'),
       ('2006-12-29', 'Dustin', 'Baker'),
       ('2007-01-16', 'Lane', 'Ramsey'),
       ('2006-06-12', 'Vernon', 'Smith'),
       ('2006-07-03', 'Blaise', 'Pearson'),
       ('2006-08-15', 'Linnea', 'Young'),
       ('2006-09-24', 'Zane', 'Bright'),
       ('2006-06-30', 'Elijah', 'Murillo'),
       ('2006-07-23', 'Candice', 'Mcbride'),
       ('2006-08-23', 'Ellice', 'Mills'),
       ('2006-09-06', 'Sutton', 'Williamson'),
       ('2006-09-20', 'Jacklyn', 'Salazar'),
       ('2006-10-23', 'Cameron', 'Dougherty'),
       ('2006-12-01', 'Reeve', 'Taylor'),
       ('2006-06-09', 'Kai', 'Watson'),
       ('2006-07-03', 'Ellory', 'Davenport'),
       ('2006-07-21', 'Fawn', 'Wiggins'),
       ('2006-09-23', 'Gavin', 'Riley'),
       ('2006-11-20', 'Anise', 'Hayden'),
       ('2006-12-21', 'Blaise', 'Jacobs'),
       ('2007-01-08', 'Louisa', 'Buck'),
       ('2006-06-10', 'Tristan', 'Dunn'),
       ('2006-06-19', 'Brendon', 'Thompson'),
       ('2006-07-26', 'Evelyn', 'Young'),
       ('2006-09-08', 'Clark', 'Cain'),
       ('2006-06-26', 'Chase', 'Harrell'),
       ('2006-07-14', 'Aiden', 'Oneal'),
       ('2006-07-27', 'Timothy', 'Hooper'),
       ('2006-08-30', 'Dezi', 'Burns'),
       ('2006-09-14', 'Syllable', 'Mcguire'),
       ('2006-10-03', 'Matilda', 'Garrison'),
       ('2006-11-30', 'Jeremy', 'Krueger'),
       ('2007-01-14', 'Clelia', 'Pollard'),
       ('2006-06-30', 'Jackson', 'Moody'),
       ('2006-07-16', 'Sherleen', 'Durham'),
       ('2006-08-26', 'Lee', 'Mathis'),
       ('2006-10-23', 'Brighton', 'Pham'),
       ('2006-12-14', 'Raine', 'Watkins'),
       ('2006-12-29', 'Dustin', 'Baker'),
       ('2006-06-06', 'Juliet', 'Rollins'),
       ('2006-06-14', 'William', 'Baker'),
       ('2006-07-05', 'Chase', 'Rich'),
       ('2006-09-01', 'Levi', 'Holland'),
       ('2006-06-10', 'Ellice', 'Fischer'),
       ('2006-07-07', 'Clelia', 'Stuart'),
       ('2006-07-23', 'Candice', 'Mcbride'),
       ('2006-08-26', 'Randall', 'Lang');


insert into classes (title, study_year)
values ('A', 11),
       ('B', 11),
       ('A', 10),
       ('B', 10);

insert into class_history (pupil_id, class_id, change_time)
values (1, 1, '2021-08-31 12:00:00'),
       (2, 1, '2021-08-31 12:00:00'),
       (3, 1, '2021-08-31 12:00:00'),
       (4, 1, '2021-08-31 12:00:00'),
       (5, 1, '2021-08-31 12:00:00'),
       (6, 1, '2021-08-31 12:00:00'),
       (7, 1, '2021-08-31 12:00:00'),
       (8, 1, '2021-08-31 12:00:00'),
       (9, 1, '2021-08-31 12:00:00'),
       (10, 1, '2021-08-31 12:00:00'),
       (11, 1, '2021-08-31 12:00:00'),
       (12, 1, '2021-08-31 12:00:00'),
       (13, 1, '2021-08-31 12:00:00'),
       (14, 1, '2021-08-31 12:00:00'),
       (15, 1, '2021-08-31 12:00:00'),
       (16, 1, '2021-08-31 12:00:00'),
       (17, 1, '2021-08-31 12:00:00'),
       (18, 1, '2021-08-31 12:00:00'),
       (19, 1, '2021-08-31 12:00:00'),
       (20, 1, '2021-08-31 12:00:00'),
       (21, 1, '2021-08-31 12:00:00'),
       (22, 1, '2021-08-31 12:00:00'),
       (23, 1, '2021-08-31 12:00:00'),
       (24, 1, '2021-08-31 12:00:00'),
       (25, 1, '2021-08-31 12:00:00'),
       (26, 1, '2021-08-31 12:00:00'),
       (27, 1, '2021-08-31 12:00:00'),
       (28, 1, '2021-08-31 12:00:00'),
       (29, 1, '2021-08-31 12:00:00'),
       (30, 1, '2021-08-31 12:00:00'),
       (31, 2, '2021-08-31 12:00:00'),
       (32, 2, '2021-08-31 12:00:00'),
       (33, 2, '2021-08-31 12:00:00'),
       (34, 2, '2021-08-31 12:00:00'),
       (35, 2, '2021-08-31 12:00:00'),
       (36, 2, '2021-08-31 12:00:00'),
       (37, 2, '2021-08-31 12:00:00'),
       (38, 2, '2021-08-31 12:00:00'),
       (39, 2, '2021-08-31 12:00:00'),
       (40, 2, '2021-08-31 12:00:00'),
       (41, 2, '2021-08-31 12:00:00'),
       (42, 2, '2021-08-31 12:00:00'),
       (43, 2, '2021-08-31 12:00:00'),
       (44, 2, '2021-08-31 12:00:00'),
       (45, 2, '2021-08-31 12:00:00'),
       (46, 2, '2021-08-31 12:00:00'),
       (47, 2, '2021-08-31 12:00:00'),
       (48, 2, '2021-08-31 12:00:00'),
       (49, 2, '2021-08-31 12:00:00'),
       (50, 2, '2021-08-31 12:00:00'),
       (51, 2, '2021-08-31 12:00:00'),
       (52, 2, '2021-08-31 12:00:00'),
       (53, 2, '2021-08-31 12:00:00'),
       (54, 2, '2021-08-31 12:00:00'),
       (55, 2, '2021-08-31 12:00:00'),
       (56, 2, '2021-08-31 12:00:00'),
       (57, 2, '2021-08-31 12:00:00'),
       (58, 2, '2021-08-31 12:00:00'),
       (59, 2, '2021-08-31 12:00:00'),
       (60, 2, '2021-08-31 12:00:00'),
       (61, 3, '2021-08-31 12:00:00'),
       (62, 3, '2021-08-31 12:00:00'),
       (63, 3, '2021-08-31 12:00:00'),
       (64, 3, '2021-08-31 12:00:00'),
       (65, 3, '2021-08-31 12:00:00'),
       (66, 3, '2021-08-31 12:00:00'),
       (67, 3, '2021-08-31 12:00:00'),
       (68, 3, '2021-08-31 12:00:00'),
       (69, 3, '2021-08-31 12:00:00'),
       (70, 3, '2021-08-31 12:00:00'),
       (71, 3, '2021-08-31 12:00:00'),
       (72, 3, '2021-08-31 12:00:00'),
       (73, 3, '2021-08-31 12:00:00'),
       (74, 3, '2021-08-31 12:00:00'),
       (75, 3, '2021-08-31 12:00:00'),
       (76, 3, '2021-08-31 12:00:00'),
       (77, 3, '2021-08-31 12:00:00'),
       (78, 3, '2021-08-31 12:00:00'),
       (79, 3, '2021-08-31 12:00:00'),
       (80, 3, '2021-08-31 12:00:00'),
       (81, 3, '2021-08-31 12:00:00'),
       (82, 3, '2021-08-31 12:00:00'),
       (83, 3, '2021-08-31 12:00:00'),
       (84, 3, '2021-08-31 12:00:00'),
       (85, 3, '2021-08-31 12:00:00'),
       (86, 3, '2021-08-31 12:00:00'),
       (87, 3, '2021-08-31 12:00:00'),
       (88, 3, '2021-08-31 12:00:00'),
       (89, 3, '2021-08-31 12:00:00'),
       (90, 3, '2021-08-31 12:00:00'),
       (91, 4, '2021-08-31 12:00:00'),
       (92, 4, '2021-08-31 12:00:00'),
       (93, 4, '2021-08-31 12:00:00'),
       (94, 4, '2021-08-31 12:00:00'),
       (95, 4, '2021-08-31 12:00:00'),
       (96, 4, '2021-08-31 12:00:00'),
       (97, 4, '2021-08-31 12:00:00'),
       (98, 4, '2021-08-31 12:00:00'),
       (99, 4, '2021-08-31 12:00:00'),
       (100, 4, '2021-08-31 12:00:00'),
       (101, 4, '2021-08-31 12:00:00'),
       (102, 4, '2021-08-31 12:00:00'),
       (103, 4, '2021-08-31 12:00:00'),
       (104, 4, '2021-08-31 12:00:00'),
       (105, 4, '2021-08-31 12:00:00'),
       (106, 4, '2021-08-31 12:00:00'),
       (107, 4, '2021-08-31 12:00:00'),
       (108, 4, '2021-08-31 12:00:00'),
       (109, 4, '2021-08-31 12:00:00'),
       (110, 4, '2021-08-31 12:00:00'),
       (111, 4, '2021-08-31 12:00:00'),
       (112, 4, '2021-08-31 12:00:00'),
       (113, 4, '2021-08-31 12:00:00'),
       (114, 4, '2021-08-31 12:00:00'),
       (115, 4, '2021-08-31 12:00:00'),
       (116, 4, '2021-08-31 12:00:00'),
       (117, 4, '2021-08-31 12:00:00'),
       (118, 4, '2021-08-31 12:00:00'),
       (119, 4, '2021-08-31 12:00:00'),
       (120, 4, '2021-08-31 12:00:00');
/*
insert into subjects (title)
values ('Debate 11'),
       ('Polish 11'),
       ('English 11'),
       ('Foreign language II 11'),
       ('Mathematics 11'),
       ('Biology 11'),
       ('Chemistry 11'),
       ('Physics 11'),
       ('Geography 11'),
       ('Informatics 11'),
       ('History 11'),
       ('Civics 11'),
       ('Astronomy 11'),
       ('Debate 10'),
       ('Polish 10'),
       ('English 10'),
       ('Foreign language II 10'),
       ('Mathematics 10'),
       ('Biology 10'),
       ('Chemistry 10'),
       ('Physics 10'),
       ('Geography 10'),
       ('Informatics 10'),
       ('History 10'),
       ('Civics 10');

insert into themes (title, subject_id, lessons_length, theme_order)
values ('BlackLivesMatter', 1, 10, 1),
       ('DoesTheGodExist', 1, 10, 2),
       ('Grammar', 2, 10, 1),
       ('Reading', 2, 20, 2),
       ('Speaking', 2, 10, 3),
       ('Grammar', 3, 10, 1),
       ('Reading', 3, 20, 2),
       ('Speaking', 3, 10, 3),
       ('Grammar', 4, 10, 1),
       ('Reading', 4, 20, 2),
       ('Speaking', 4, 10, 3),
       ('Geometry', 5, 30, 1),
       ('Algebra', 5, 30, 2),
       ('Anatomy', 6, 10, 1),
       ('Diseases', 6, 10, 2),
       ('Lab', 7, 20, 1),
       ('Theory', 7, 20, 2),
       ('Lab', 8, 20, 1),
       ('Theory', 8, 20, 2),
       ('GlobalRelationships', 9, 10, 1),
       ('Environment', 9, 10, 2),
       ('Python', 10, 20, 1),
       ('World', 11, 20, 1),
       ('Poland', 11, 20, 2),
       ('Laws', 12, 20, 1),
       ('UpTheSky', 13, 20, 1),
       ('WhatEducationIsFor', 14, 10, 1),
       ('SensOfLife', 14, 10, 2),
       ('Grammar', 15, 10, 1),
       ('Reading', 15, 20, 2),
       ('Speaking', 15, 10, 3),
       ('Grammar', 16, 10, 1),
       ('Reading', 16, 20, 2),
       ('Speaking', 16, 10, 3),
       ('Grammar', 17, 10, 1),
       ('Reading', 17, 20, 2),
       ('Speaking', 17, 10, 3),
       ('Geometry', 18, 30, 1),
       ('Algebra', 18, 30, 2),
       ('Bacteria', 19, 10, 1),
       ('Heredity And Evolution', 19, 10, 2),
       ('Lab', 20, 20, 1),
       ('Theory', 20, 20, 2),
       ('Lab', 21, 20, 1),
       ('Theory', 21, 20, 2),
       ('Countries', 22, 10, 1),
       ('Climate', 22, 10, 2),
       ('C++', 23, 20, 1),
       ('World', 24, 20, 1),
       ('Poland', 24, 20, 2),
       ('Politics', 25, 20, 2);

insert into groups (title, subject_id, class_id)
values ('Debate 11A 1', 1, 1),
       ('Debate 11A 2', 1, 1),
       ('Polish 11A 1', 2, 1),
       ('Polish 11A 2', 2, 1),
       ('English 11A 1', 3, 1),
       ('English 11A 2', 3, 1),
       ('Foreign languageII 11A 1', 4, 1),
       ('Foreign languageII 11A 2', 4, 1),
       ('Mathematics 11A 1', 5, 1),
       ('Biology 11A 1', 6, 1),
       ('Chemistry 11A 1', 7, 1),
       ('Physics 11A 1', 8, 1),
       ('Geography 11A 1', 9, 1),
       ('Informatics 11A 1', 10, 1),
       ('Informatics 11A 2', 10, 1),
       ('History 11A 1', 11, 1),
       ('Civics 11A 1', 12, 1),
       ('Astronomy 11A 1', 13, 1),
       ('Debate 11B 1', 1, 2),
       ('Debate 11B 2', 1, 2),
       ('Polish 11B 1', 2, 2),
       ('Polish 11B 2', 2, 2),
       ('English 11B 1', 3, 2),
       ('English 11B 2', 3, 2),
       ('Foreign languageII 11B 1', 4, 2),
       ('Foreign languageII 11B 2', 4, 2),
       ('Mathematics 11B 1', 5, 2),
       ('Biology 11B 1', 6, 2),
       ('Chemistry 11B 1', 7, 2),
       ('Physics 11B 1', 8, 2),
       ('Geography 11B 1', 9, 2),
       ('Informatics 11B 1', 10, 2),
       ('Informatics 11B 2', 10, 2),
       ('History 11B 1', 11, 2),
       ('Civics 11B 1', 12, 2),
       ('Astronomy 11B 1', 13, 2),
       ('Debate 10A 1', 14, 3),
       ('Debate 10A 2', 14, 3),
       ('Polish 10A 1', 15, 3),
       ('Polish 10A 2', 15, 3),
       ('English 10A 1', 16, 3),
       ('English 10A 2', 16, 3),
       ('Foreign languageII 10A 1', 17, 3),
       ('Foreign languageII 10A 2', 17, 3),
       ('Mathematics 10A 1', 18, 3),
       ('Biology 10A 1', 19, 3),
       ('Chemistry 10A 1', 20, 3),
       ('Physics 10A 1', 21, 3),
       ('Geography 10A 1', 22, 3),
       ('Informatics 10A 1', 23, 3),
       ('Informatics 10A 2', 23, 3),
       ('History 10A 1', 24, 3),
       ('Civics 10A 1', 25, 3),
       ('Debate 10B 1', 14, 4),
       ('Debate 10B 2', 14, 4),
       ('Polish 10B 1', 15, 4),
       ('Polish 10B 2', 15, 4),
       ('English 10B 1', 16, 4),
       ('English 10B 2', 16, 4),
       ('Foreign languageII 10B 1', 17, 4),
       ('Foreign languageII 10B 2', 17, 4),
       ('Mathematics 10B 1', 18, 4),
       ('Biology 10B 1', 19, 4),
       ('Chemistry 10B 1', 20, 4),
       ('Physics 10B 1', 21, 4),
       ('Geography 10B 1', 22, 4),
       ('Informatics 10B 1', 23, 4),
       ('Informatics 10B 2', 23, 4),
       ('History 10B 1', 24, 4),
       ('Civics 10B 1', 25, 4);

insert into groups_history (pupil_id, group_id, begin_time)
values (1, 1, '2021-08-31 13:00:00'),
       (1, 3, '2021-08-31 13:00:00'),
       (1, 5, '2021-08-31 13:00:00'),
       (1, 7, '2021-08-31 13:00:00'),
       (1, 9, '2021-08-31 13:00:00'),
       (1, 10, '2021-08-31 13:00:00'),
       (1, 11, '2021-08-31 13:00:00'),
       (1, 12, '2021-08-31 13:00:00'),
       (1, 13, '2021-08-31 13:00:00'),
       (1, 14, '2021-08-31 13:00:00'),
       (1, 16, '2021-08-31 13:00:00'),
       (1, 17, '2021-08-31 13:00:00'),
       (1, 18, '2021-08-31 13:00:00'),
       (2, 2, '2021-08-31 13:00:00'),
       (2, 4, '2021-08-31 13:00:00'),
       (2, 6, '2021-08-31 13:00:00'),
       (2, 8, '2021-08-31 13:00:00'),
       (2, 9, '2021-08-31 13:00:00'),
       (2, 10, '2021-08-31 13:00:00'),
       (2, 11, '2021-08-31 13:00:00'),
       (2, 12, '2021-08-31 13:00:00'),
       (2, 13, '2021-08-31 13:00:00'),
       (2, 15, '2021-08-31 13:00:00'),
       (2, 16, '2021-08-31 13:00:00'),
       (2, 17, '2021-08-31 13:00:00'),
       (2, 18, '2021-08-31 13:00:00'),
       (3, 1, '2021-08-31 13:00:00'),
       (3, 3, '2021-08-31 13:00:00'),
       (3, 5, '2021-08-31 13:00:00'),
       (3, 7, '2021-08-31 13:00:00'),
       (3, 9, '2021-08-31 13:00:00'),
       (3, 10, '2021-08-31 13:00:00'),
       (3, 11, '2021-08-31 13:00:00'),
       (3, 12, '2021-08-31 13:00:00'),
       (3, 13, '2021-08-31 13:00:00'),
       (3, 14, '2021-08-31 13:00:00'),
       (3, 16, '2021-08-31 13:00:00'),
       (3, 17, '2021-08-31 13:00:00'),
       (3, 18, '2021-08-31 13:00:00'),
       (4, 2, '2021-08-31 13:00:00'),
       (4, 4, '2021-08-31 13:00:00'),
       (4, 6, '2021-08-31 13:00:00'),
       (4, 8, '2021-08-31 13:00:00'),
       (4, 9, '2021-08-31 13:00:00'),
       (4, 10, '2021-08-31 13:00:00'),
       (4, 11, '2021-08-31 13:00:00'),
       (4, 12, '2021-08-31 13:00:00'),
       (4, 13, '2021-08-31 13:00:00'),
       (4, 15, '2021-08-31 13:00:00'),
       (4, 16, '2021-08-31 13:00:00'),
       (4, 17, '2021-08-31 13:00:00'),
       (4, 18, '2021-08-31 13:00:00'),
       (5, 1, '2021-08-31 13:00:00'),
       (5, 3, '2021-08-31 13:00:00'),
       (5, 5, '2021-08-31 13:00:00'),
       (5, 7, '2021-08-31 13:00:00'),
       (5, 9, '2021-08-31 13:00:00'),
       (5, 10, '2021-08-31 13:00:00'),
       (5, 11, '2021-08-31 13:00:00'),
       (5, 12, '2021-08-31 13:00:00'),
       (5, 13, '2021-08-31 13:00:00'),
       (5, 14, '2021-08-31 13:00:00'),
       (5, 16, '2021-08-31 13:00:00'),
       (5, 17, '2021-08-31 13:00:00'),
       (5, 18, '2021-08-31 13:00:00'),
       (6, 2, '2021-08-31 13:00:00'),
       (6, 4, '2021-08-31 13:00:00'),
       (6, 6, '2021-08-31 13:00:00'),
       (6, 8, '2021-08-31 13:00:00'),
       (6, 9, '2021-08-31 13:00:00'),
       (6, 10, '2021-08-31 13:00:00'),
       (6, 11, '2021-08-31 13:00:00'),
       (6, 12, '2021-08-31 13:00:00'),
       (6, 13, '2021-08-31 13:00:00'),
       (6, 15, '2021-08-31 13:00:00'),
       (6, 16, '2021-08-31 13:00:00'),
       (6, 17, '2021-08-31 13:00:00'),
       (6, 18, '2021-08-31 13:00:00'),
       (7, 1, '2021-08-31 13:00:00'),
       (7, 3, '2021-08-31 13:00:00'),
       (7, 5, '2021-08-31 13:00:00'),
       (7, 7, '2021-08-31 13:00:00'),
       (7, 9, '2021-08-31 13:00:00'),
       (7, 10, '2021-08-31 13:00:00'),
       (7, 11, '2021-08-31 13:00:00'),
       (7, 12, '2021-08-31 13:00:00'),
       (7, 13, '2021-08-31 13:00:00'),
       (7, 14, '2021-08-31 13:00:00'),
       (7, 16, '2021-08-31 13:00:00'),
       (7, 17, '2021-08-31 13:00:00'),
       (7, 18, '2021-08-31 13:00:00'),
       (8, 2, '2021-08-31 13:00:00'),
       (8, 4, '2021-08-31 13:00:00'),
       (8, 6, '2021-08-31 13:00:00'),
       (8, 8, '2021-08-31 13:00:00'),
       (8, 9, '2021-08-31 13:00:00'),
       (8, 10, '2021-08-31 13:00:00'),
       (8, 11, '2021-08-31 13:00:00'),
       (8, 12, '2021-08-31 13:00:00'),
       (8, 13, '2021-08-31 13:00:00'),
       (8, 15, '2021-08-31 13:00:00'),
       (8, 16, '2021-08-31 13:00:00'),
       (8, 17, '2021-08-31 13:00:00'),
       (8, 18, '2021-08-31 13:00:00'),
       (9, 1, '2021-08-31 13:00:00'),
       (9, 3, '2021-08-31 13:00:00'),
       (9, 5, '2021-08-31 13:00:00'),
       (9, 7, '2021-08-31 13:00:00'),
       (9, 9, '2021-08-31 13:00:00'),
       (9, 10, '2021-08-31 13:00:00'),
       (9, 11, '2021-08-31 13:00:00'),
       (9, 12, '2021-08-31 13:00:00'),
       (9, 13, '2021-08-31 13:00:00'),
       (9, 14, '2021-08-31 13:00:00'),
       (9, 16, '2021-08-31 13:00:00'),
       (9, 17, '2021-08-31 13:00:00'),
       (9, 18, '2021-08-31 13:00:00'),
       (10, 2, '2021-08-31 13:00:00'),
       (10, 4, '2021-08-31 13:00:00'),
       (10, 6, '2021-08-31 13:00:00'),
       (10, 8, '2021-08-31 13:00:00'),
       (10, 9, '2021-08-31 13:00:00'),
       (10, 10, '2021-08-31 13:00:00'),
       (10, 11, '2021-08-31 13:00:00'),
       (10, 12, '2021-08-31 13:00:00'),
       (10, 13, '2021-08-31 13:00:00'),
       (10, 15, '2021-08-31 13:00:00'),
       (10, 16, '2021-08-31 13:00:00'),
       (10, 17, '2021-08-31 13:00:00'),
       (10, 18, '2021-08-31 13:00:00'),
       (11, 1, '2021-08-31 13:00:00'),
       (11, 3, '2021-08-31 13:00:00'),
       (11, 5, '2021-08-31 13:00:00'),
       (11, 7, '2021-08-31 13:00:00'),
       (11, 9, '2021-08-31 13:00:00'),
       (11, 10, '2021-08-31 13:00:00'),
       (11, 11, '2021-08-31 13:00:00'),
       (11, 12, '2021-08-31 13:00:00'),
       (11, 13, '2021-08-31 13:00:00'),
       (11, 14, '2021-08-31 13:00:00'),
       (11, 16, '2021-08-31 13:00:00'),
       (11, 17, '2021-08-31 13:00:00'),
       (11, 18, '2021-08-31 13:00:00'),
       (12, 2, '2021-08-31 13:00:00'),
       (12, 4, '2021-08-31 13:00:00'),
       (12, 6, '2021-08-31 13:00:00'),
       (12, 8, '2021-08-31 13:00:00'),
       (12, 9, '2021-08-31 13:00:00'),
       (12, 10, '2021-08-31 13:00:00'),
       (12, 11, '2021-08-31 13:00:00'),
       (12, 12, '2021-08-31 13:00:00'),
       (12, 13, '2021-08-31 13:00:00'),
       (12, 15, '2021-08-31 13:00:00'),
       (12, 16, '2021-08-31 13:00:00'),
       (12, 17, '2021-08-31 13:00:00'),
       (12, 18, '2021-08-31 13:00:00'),
       (13, 1, '2021-08-31 13:00:00'),
       (13, 3, '2021-08-31 13:00:00'),
       (13, 5, '2021-08-31 13:00:00'),
       (13, 7, '2021-08-31 13:00:00'),
       (13, 9, '2021-08-31 13:00:00'),
       (13, 10, '2021-08-31 13:00:00'),
       (13, 11, '2021-08-31 13:00:00'),
       (13, 12, '2021-08-31 13:00:00'),
       (13, 13, '2021-08-31 13:00:00'),
       (13, 14, '2021-08-31 13:00:00'),
       (13, 16, '2021-08-31 13:00:00'),
       (13, 17, '2021-08-31 13:00:00'),
       (13, 18, '2021-08-31 13:00:00'),
       (14, 2, '2021-08-31 13:00:00'),
       (14, 4, '2021-08-31 13:00:00'),
       (14, 6, '2021-08-31 13:00:00'),
       (14, 8, '2021-08-31 13:00:00'),
       (14, 9, '2021-08-31 13:00:00'),
       (14, 10, '2021-08-31 13:00:00'),
       (14, 11, '2021-08-31 13:00:00'),
       (14, 12, '2021-08-31 13:00:00'),
       (14, 13, '2021-08-31 13:00:00'),
       (14, 15, '2021-08-31 13:00:00'),
       (14, 16, '2021-08-31 13:00:00'),
       (14, 17, '2021-08-31 13:00:00'),
       (14, 18, '2021-08-31 13:00:00'),
       (15, 1, '2021-08-31 13:00:00'),
       (15, 3, '2021-08-31 13:00:00'),
       (15, 5, '2021-08-31 13:00:00'),
       (15, 7, '2021-08-31 13:00:00'),
       (15, 9, '2021-08-31 13:00:00'),
       (15, 10, '2021-08-31 13:00:00'),
       (15, 11, '2021-08-31 13:00:00'),
       (15, 12, '2021-08-31 13:00:00'),
       (15, 13, '2021-08-31 13:00:00'),
       (15, 14, '2021-08-31 13:00:00'),
       (15, 16, '2021-08-31 13:00:00'),
       (15, 17, '2021-08-31 13:00:00'),
       (15, 18, '2021-08-31 13:00:00'),
       (16, 2, '2021-08-31 13:00:00'),
       (16, 4, '2021-08-31 13:00:00'),
       (16, 6, '2021-08-31 13:00:00'),
       (16, 8, '2021-08-31 13:00:00'),
       (16, 9, '2021-08-31 13:00:00'),
       (16, 10, '2021-08-31 13:00:00'),
       (16, 11, '2021-08-31 13:00:00'),
       (16, 12, '2021-08-31 13:00:00'),
       (16, 13, '2021-08-31 13:00:00'),
       (16, 15, '2021-08-31 13:00:00'),
       (16, 16, '2021-08-31 13:00:00'),
       (16, 17, '2021-08-31 13:00:00'),
       (16, 18, '2021-08-31 13:00:00'),
       (17, 1, '2021-08-31 13:00:00'),
       (17, 3, '2021-08-31 13:00:00'),
       (17, 5, '2021-08-31 13:00:00'),
       (17, 7, '2021-08-31 13:00:00'),
       (17, 9, '2021-08-31 13:00:00'),
       (17, 10, '2021-08-31 13:00:00'),
       (17, 11, '2021-08-31 13:00:00'),
       (17, 12, '2021-08-31 13:00:00'),
       (17, 13, '2021-08-31 13:00:00'),
       (17, 14, '2021-08-31 13:00:00'),
       (17, 16, '2021-08-31 13:00:00'),
       (17, 17, '2021-08-31 13:00:00'),
       (17, 18, '2021-08-31 13:00:00'),
       (18, 2, '2021-08-31 13:00:00'),
       (18, 4, '2021-08-31 13:00:00'),
       (18, 6, '2021-08-31 13:00:00'),
       (18, 8, '2021-08-31 13:00:00'),
       (18, 9, '2021-08-31 13:00:00'),
       (18, 10, '2021-08-31 13:00:00'),
       (18, 11, '2021-08-31 13:00:00'),
       (18, 12, '2021-08-31 13:00:00'),
       (18, 13, '2021-08-31 13:00:00'),
       (18, 15, '2021-08-31 13:00:00'),
       (18, 16, '2021-08-31 13:00:00'),
       (18, 17, '2021-08-31 13:00:00'),
       (18, 18, '2021-08-31 13:00:00'),
       (19, 1, '2021-08-31 13:00:00'),
       (19, 3, '2021-08-31 13:00:00'),
       (19, 5, '2021-08-31 13:00:00'),
       (19, 7, '2021-08-31 13:00:00'),
       (19, 9, '2021-08-31 13:00:00'),
       (19, 10, '2021-08-31 13:00:00'),
       (19, 11, '2021-08-31 13:00:00'),
       (19, 12, '2021-08-31 13:00:00'),
       (19, 13, '2021-08-31 13:00:00'),
       (19, 14, '2021-08-31 13:00:00'),
       (19, 16, '2021-08-31 13:00:00'),
       (19, 17, '2021-08-31 13:00:00'),
       (19, 18, '2021-08-31 13:00:00'),
       (20, 2, '2021-08-31 13:00:00'),
       (20, 4, '2021-08-31 13:00:00'),
       (20, 6, '2021-08-31 13:00:00'),
       (20, 8, '2021-08-31 13:00:00'),
       (20, 9, '2021-08-31 13:00:00'),
       (20, 10, '2021-08-31 13:00:00'),
       (20, 11, '2021-08-31 13:00:00'),
       (20, 12, '2021-08-31 13:00:00'),
       (20, 13, '2021-08-31 13:00:00'),
       (20, 15, '2021-08-31 13:00:00'),
       (20, 16, '2021-08-31 13:00:00'),
       (20, 17, '2021-08-31 13:00:00'),
       (20, 18, '2021-08-31 13:00:00'),
       (21, 1, '2021-08-31 13:00:00'),
       (21, 3, '2021-08-31 13:00:00'),
       (21, 5, '2021-08-31 13:00:00'),
       (21, 7, '2021-08-31 13:00:00'),
       (21, 9, '2021-08-31 13:00:00'),
       (21, 10, '2021-08-31 13:00:00'),
       (21, 11, '2021-08-31 13:00:00'),
       (21, 12, '2021-08-31 13:00:00'),
       (21, 13, '2021-08-31 13:00:00'),
       (21, 14, '2021-08-31 13:00:00'),
       (21, 16, '2021-08-31 13:00:00'),
       (21, 17, '2021-08-31 13:00:00'),
       (21, 18, '2021-08-31 13:00:00'),
       (22, 2, '2021-08-31 13:00:00'),
       (22, 4, '2021-08-31 13:00:00'),
       (22, 6, '2021-08-31 13:00:00'),
       (22, 8, '2021-08-31 13:00:00'),
       (22, 9, '2021-08-31 13:00:00'),
       (22, 10, '2021-08-31 13:00:00'),
       (22, 11, '2021-08-31 13:00:00'),
       (22, 12, '2021-08-31 13:00:00'),
       (22, 13, '2021-08-31 13:00:00'),
       (22, 15, '2021-08-31 13:00:00'),
       (22, 16, '2021-08-31 13:00:00'),
       (22, 17, '2021-08-31 13:00:00'),
       (22, 18, '2021-08-31 13:00:00'),
       (23, 1, '2021-08-31 13:00:00'),
       (23, 3, '2021-08-31 13:00:00'),
       (23, 5, '2021-08-31 13:00:00'),
       (23, 7, '2021-08-31 13:00:00'),
       (23, 9, '2021-08-31 13:00:00'),
       (23, 10, '2021-08-31 13:00:00'),
       (23, 11, '2021-08-31 13:00:00'),
       (23, 12, '2021-08-31 13:00:00'),
       (23, 13, '2021-08-31 13:00:00'),
       (23, 14, '2021-08-31 13:00:00'),
       (23, 16, '2021-08-31 13:00:00'),
       (23, 17, '2021-08-31 13:00:00'),
       (23, 18, '2021-08-31 13:00:00'),
       (24, 2, '2021-08-31 13:00:00'),
       (24, 4, '2021-08-31 13:00:00'),
       (24, 6, '2021-08-31 13:00:00'),
       (24, 8, '2021-08-31 13:00:00'),
       (24, 9, '2021-08-31 13:00:00'),
       (24, 10, '2021-08-31 13:00:00'),
       (24, 11, '2021-08-31 13:00:00'),
       (24, 12, '2021-08-31 13:00:00'),
       (24, 13, '2021-08-31 13:00:00'),
       (24, 15, '2021-08-31 13:00:00'),
       (24, 16, '2021-08-31 13:00:00'),
       (24, 17, '2021-08-31 13:00:00'),
       (24, 18, '2021-08-31 13:00:00'),
       (25, 1, '2021-08-31 13:00:00'),
       (25, 3, '2021-08-31 13:00:00'),
       (25, 5, '2021-08-31 13:00:00'),
       (25, 7, '2021-08-31 13:00:00'),
       (25, 9, '2021-08-31 13:00:00'),
       (25, 10, '2021-08-31 13:00:00'),
       (25, 11, '2021-08-31 13:00:00'),
       (25, 12, '2021-08-31 13:00:00'),
       (25, 13, '2021-08-31 13:00:00'),
       (25, 14, '2021-08-31 13:00:00'),
       (25, 16, '2021-08-31 13:00:00'),
       (25, 17, '2021-08-31 13:00:00'),
       (25, 18, '2021-08-31 13:00:00'),
       (26, 2, '2021-08-31 13:00:00'),
       (26, 4, '2021-08-31 13:00:00'),
       (26, 6, '2021-08-31 13:00:00'),
       (26, 8, '2021-08-31 13:00:00'),
       (26, 9, '2021-08-31 13:00:00'),
       (26, 10, '2021-08-31 13:00:00'),
       (26, 11, '2021-08-31 13:00:00'),
       (26, 12, '2021-08-31 13:00:00'),
       (26, 13, '2021-08-31 13:00:00'),
       (26, 15, '2021-08-31 13:00:00'),
       (26, 16, '2021-08-31 13:00:00'),
       (26, 17, '2021-08-31 13:00:00'),
       (26, 18, '2021-08-31 13:00:00'),
       (27, 1, '2021-08-31 13:00:00'),
       (27, 3, '2021-08-31 13:00:00'),
       (27, 5, '2021-08-31 13:00:00'),
       (27, 7, '2021-08-31 13:00:00'),
       (27, 9, '2021-08-31 13:00:00'),
       (27, 10, '2021-08-31 13:00:00'),
       (27, 11, '2021-08-31 13:00:00'),
       (27, 12, '2021-08-31 13:00:00'),
       (27, 13, '2021-08-31 13:00:00'),
       (27, 14, '2021-08-31 13:00:00'),
       (27, 16, '2021-08-31 13:00:00'),
       (27, 17, '2021-08-31 13:00:00'),
       (27, 18, '2021-08-31 13:00:00'),
       (28, 2, '2021-08-31 13:00:00'),
       (28, 4, '2021-08-31 13:00:00'),
       (28, 6, '2021-08-31 13:00:00'),
       (28, 8, '2021-08-31 13:00:00'),
       (28, 9, '2021-08-31 13:00:00'),
       (28, 10, '2021-08-31 13:00:00'),
       (28, 11, '2021-08-31 13:00:00'),
       (28, 12, '2021-08-31 13:00:00'),
       (28, 13, '2021-08-31 13:00:00'),
       (28, 15, '2021-08-31 13:00:00'),
       (28, 16, '2021-08-31 13:00:00'),
       (28, 17, '2021-08-31 13:00:00'),
       (28, 18, '2021-08-31 13:00:00'),
       (29, 1, '2021-08-31 13:00:00'),
       (29, 3, '2021-08-31 13:00:00'),
       (29, 5, '2021-08-31 13:00:00'),
       (29, 7, '2021-08-31 13:00:00'),
       (29, 9, '2021-08-31 13:00:00'),
       (29, 10, '2021-08-31 13:00:00'),
       (29, 11, '2021-08-31 13:00:00'),
       (29, 12, '2021-08-31 13:00:00'),
       (29, 13, '2021-08-31 13:00:00'),
       (29, 14, '2021-08-31 13:00:00'),
       (29, 16, '2021-08-31 13:00:00'),
       (29, 17, '2021-08-31 13:00:00'),
       (29, 18, '2021-08-31 13:00:00'),
       (30, 2, '2021-08-31 13:00:00'),
       (30, 4, '2021-08-31 13:00:00'),
       (30, 6, '2021-08-31 13:00:00'),
       (30, 8, '2021-08-31 13:00:00'),
       (30, 9, '2021-08-31 13:00:00'),
       (30, 10, '2021-08-31 13:00:00'),
       (30, 11, '2021-08-31 13:00:00'),
       (30, 12, '2021-08-31 13:00:00'),
       (30, 13, '2021-08-31 13:00:00'),
       (30, 15, '2021-08-31 13:00:00'),
       (30, 16, '2021-08-31 13:00:00'),
       (30, 17, '2021-08-31 13:00:00'),
       (30, 18, '2021-08-31 13:00:00'),
       (31, 19, '2021-08-31 13:00:00'),
       (31, 21, '2021-08-31 13:00:00'),
       (31, 23, '2021-08-31 13:00:00'),
       (31, 25, '2021-08-31 13:00:00'),
       (31, 27, '2021-08-31 13:00:00'),
       (31, 28, '2021-08-31 13:00:00'),
       (31, 29, '2021-08-31 13:00:00'),
       (31, 30, '2021-08-31 13:00:00'),
       (31, 31, '2021-08-31 13:00:00'),
       (31, 32, '2021-08-31 13:00:00'),
       (31, 34, '2021-08-31 13:00:00'),
       (31, 35, '2021-08-31 13:00:00'),
       (31, 36, '2021-08-31 13:00:00'),
       (32, 20, '2021-08-31 13:00:00'),
       (32, 22, '2021-08-31 13:00:00'),
       (32, 24, '2021-08-31 13:00:00'),
       (32, 26, '2021-08-31 13:00:00'),
       (32, 27, '2021-08-31 13:00:00'),
       (32, 28, '2021-08-31 13:00:00'),
       (32, 29, '2021-08-31 13:00:00'),
       (32, 30, '2021-08-31 13:00:00'),
       (32, 31, '2021-08-31 13:00:00'),
       (32, 33, '2021-08-31 13:00:00'),
       (32, 34, '2021-08-31 13:00:00'),
       (32, 35, '2021-08-31 13:00:00'),
       (32, 36, '2021-08-31 13:00:00'),
       (33, 19, '2021-08-31 13:00:00'),
       (33, 21, '2021-08-31 13:00:00'),
       (33, 23, '2021-08-31 13:00:00'),
       (33, 25, '2021-08-31 13:00:00'),
       (33, 27, '2021-08-31 13:00:00'),
       (33, 28, '2021-08-31 13:00:00'),
       (33, 29, '2021-08-31 13:00:00'),
       (33, 30, '2021-08-31 13:00:00'),
       (33, 31, '2021-08-31 13:00:00'),
       (33, 32, '2021-08-31 13:00:00'),
       (33, 34, '2021-08-31 13:00:00'),
       (33, 35, '2021-08-31 13:00:00'),
       (33, 36, '2021-08-31 13:00:00'),
       (34, 20, '2021-08-31 13:00:00'),
       (34, 22, '2021-08-31 13:00:00'),
       (34, 24, '2021-08-31 13:00:00'),
       (34, 26, '2021-08-31 13:00:00'),
       (34, 27, '2021-08-31 13:00:00'),
       (34, 28, '2021-08-31 13:00:00'),
       (34, 29, '2021-08-31 13:00:00'),
       (34, 30, '2021-08-31 13:00:00'),
       (34, 31, '2021-08-31 13:00:00'),
       (34, 33, '2021-08-31 13:00:00'),
       (34, 34, '2021-08-31 13:00:00'),
       (34, 35, '2021-08-31 13:00:00'),
       (34, 36, '2021-08-31 13:00:00'),
       (35, 19, '2021-08-31 13:00:00'),
       (35, 21, '2021-08-31 13:00:00'),
       (35, 23, '2021-08-31 13:00:00'),
       (35, 25, '2021-08-31 13:00:00'),
       (35, 27, '2021-08-31 13:00:00'),
       (35, 28, '2021-08-31 13:00:00'),
       (35, 29, '2021-08-31 13:00:00'),
       (35, 30, '2021-08-31 13:00:00'),
       (35, 31, '2021-08-31 13:00:00'),
       (35, 32, '2021-08-31 13:00:00'),
       (35, 34, '2021-08-31 13:00:00'),
       (35, 35, '2021-08-31 13:00:00'),
       (35, 36, '2021-08-31 13:00:00'),
       (36, 20, '2021-08-31 13:00:00'),
       (36, 22, '2021-08-31 13:00:00'),
       (36, 24, '2021-08-31 13:00:00'),
       (36, 26, '2021-08-31 13:00:00'),
       (36, 27, '2021-08-31 13:00:00'),
       (36, 28, '2021-08-31 13:00:00'),
       (36, 29, '2021-08-31 13:00:00'),
       (36, 30, '2021-08-31 13:00:00'),
       (36, 31, '2021-08-31 13:00:00'),
       (36, 33, '2021-08-31 13:00:00'),
       (36, 34, '2021-08-31 13:00:00'),
       (36, 35, '2021-08-31 13:00:00'),
       (36, 36, '2021-08-31 13:00:00'),
       (37, 19, '2021-08-31 13:00:00'),
       (37, 21, '2021-08-31 13:00:00'),
       (37, 23, '2021-08-31 13:00:00'),
       (37, 25, '2021-08-31 13:00:00'),
       (37, 27, '2021-08-31 13:00:00'),
       (37, 28, '2021-08-31 13:00:00'),
       (37, 29, '2021-08-31 13:00:00'),
       (37, 30, '2021-08-31 13:00:00'),
       (37, 31, '2021-08-31 13:00:00'),
       (37, 32, '2021-08-31 13:00:00'),
       (37, 34, '2021-08-31 13:00:00'),
       (37, 35, '2021-08-31 13:00:00'),
       (37, 36, '2021-08-31 13:00:00'),
       (38, 20, '2021-08-31 13:00:00'),
       (38, 22, '2021-08-31 13:00:00'),
       (38, 24, '2021-08-31 13:00:00'),
       (38, 26, '2021-08-31 13:00:00'),
       (38, 27, '2021-08-31 13:00:00'),
       (38, 28, '2021-08-31 13:00:00'),
       (38, 29, '2021-08-31 13:00:00'),
       (38, 30, '2021-08-31 13:00:00'),
       (38, 31, '2021-08-31 13:00:00'),
       (38, 33, '2021-08-31 13:00:00'),
       (38, 34, '2021-08-31 13:00:00'),
       (38, 35, '2021-08-31 13:00:00'),
       (38, 36, '2021-08-31 13:00:00'),
       (39, 19, '2021-08-31 13:00:00'),
       (39, 21, '2021-08-31 13:00:00'),
       (39, 23, '2021-08-31 13:00:00'),
       (39, 25, '2021-08-31 13:00:00'),
       (39, 27, '2021-08-31 13:00:00'),
       (39, 28, '2021-08-31 13:00:00'),
       (39, 29, '2021-08-31 13:00:00'),
       (39, 30, '2021-08-31 13:00:00'),
       (39, 31, '2021-08-31 13:00:00'),
       (39, 32, '2021-08-31 13:00:00'),
       (39, 34, '2021-08-31 13:00:00'),
       (39, 35, '2021-08-31 13:00:00'),
       (39, 36, '2021-08-31 13:00:00'),
       (40, 20, '2021-08-31 13:00:00'),
       (40, 22, '2021-08-31 13:00:00'),
       (40, 24, '2021-08-31 13:00:00'),
       (40, 26, '2021-08-31 13:00:00'),
       (40, 27, '2021-08-31 13:00:00'),
       (40, 28, '2021-08-31 13:00:00'),
       (40, 29, '2021-08-31 13:00:00'),
       (40, 30, '2021-08-31 13:00:00'),
       (40, 31, '2021-08-31 13:00:00'),
       (40, 33, '2021-08-31 13:00:00'),
       (40, 34, '2021-08-31 13:00:00'),
       (40, 35, '2021-08-31 13:00:00'),
       (40, 36, '2021-08-31 13:00:00'),
       (41, 19, '2021-08-31 13:00:00'),
       (41, 21, '2021-08-31 13:00:00'),
       (41, 23, '2021-08-31 13:00:00'),
       (41, 25, '2021-08-31 13:00:00'),
       (41, 27, '2021-08-31 13:00:00'),
       (41, 28, '2021-08-31 13:00:00'),
       (41, 29, '2021-08-31 13:00:00'),
       (41, 30, '2021-08-31 13:00:00'),
       (41, 31, '2021-08-31 13:00:00'),
       (41, 32, '2021-08-31 13:00:00'),
       (41, 34, '2021-08-31 13:00:00'),
       (41, 35, '2021-08-31 13:00:00'),
       (41, 36, '2021-08-31 13:00:00'),
       (42, 20, '2021-08-31 13:00:00'),
       (42, 22, '2021-08-31 13:00:00'),
       (42, 24, '2021-08-31 13:00:00'),
       (42, 26, '2021-08-31 13:00:00'),
       (42, 27, '2021-08-31 13:00:00'),
       (42, 28, '2021-08-31 13:00:00'),
       (42, 29, '2021-08-31 13:00:00'),
       (42, 30, '2021-08-31 13:00:00'),
       (42, 31, '2021-08-31 13:00:00'),
       (42, 33, '2021-08-31 13:00:00'),
       (42, 34, '2021-08-31 13:00:00'),
       (42, 35, '2021-08-31 13:00:00'),
       (42, 36, '2021-08-31 13:00:00'),
       (43, 19, '2021-08-31 13:00:00'),
       (43, 21, '2021-08-31 13:00:00'),
       (43, 23, '2021-08-31 13:00:00'),
       (43, 25, '2021-08-31 13:00:00'),
       (43, 27, '2021-08-31 13:00:00'),
       (43, 28, '2021-08-31 13:00:00'),
       (43, 29, '2021-08-31 13:00:00'),
       (43, 30, '2021-08-31 13:00:00'),
       (43, 31, '2021-08-31 13:00:00'),
       (43, 32, '2021-08-31 13:00:00'),
       (43, 34, '2021-08-31 13:00:00'),
       (43, 35, '2021-08-31 13:00:00'),
       (43, 36, '2021-08-31 13:00:00'),
       (44, 20, '2021-08-31 13:00:00'),
       (44, 22, '2021-08-31 13:00:00'),
       (44, 24, '2021-08-31 13:00:00'),
       (44, 26, '2021-08-31 13:00:00'),
       (44, 27, '2021-08-31 13:00:00'),
       (44, 28, '2021-08-31 13:00:00'),
       (44, 29, '2021-08-31 13:00:00'),
       (44, 30, '2021-08-31 13:00:00'),
       (44, 31, '2021-08-31 13:00:00'),
       (44, 33, '2021-08-31 13:00:00'),
       (44, 34, '2021-08-31 13:00:00'),
       (44, 35, '2021-08-31 13:00:00'),
       (44, 36, '2021-08-31 13:00:00'),
       (45, 19, '2021-08-31 13:00:00'),
       (45, 21, '2021-08-31 13:00:00'),
       (45, 23, '2021-08-31 13:00:00'),
       (45, 25, '2021-08-31 13:00:00'),
       (45, 27, '2021-08-31 13:00:00'),
       (45, 28, '2021-08-31 13:00:00'),
       (45, 29, '2021-08-31 13:00:00'),
       (45, 30, '2021-08-31 13:00:00'),
       (45, 31, '2021-08-31 13:00:00'),
       (45, 32, '2021-08-31 13:00:00'),
       (45, 34, '2021-08-31 13:00:00'),
       (45, 35, '2021-08-31 13:00:00'),
       (45, 36, '2021-08-31 13:00:00'),
       (46, 20, '2021-08-31 13:00:00'),
       (46, 22, '2021-08-31 13:00:00'),
       (46, 24, '2021-08-31 13:00:00'),
       (46, 26, '2021-08-31 13:00:00'),
       (46, 27, '2021-08-31 13:00:00'),
       (46, 28, '2021-08-31 13:00:00'),
       (46, 29, '2021-08-31 13:00:00'),
       (46, 30, '2021-08-31 13:00:00'),
       (46, 31, '2021-08-31 13:00:00'),
       (46, 33, '2021-08-31 13:00:00'),
       (46, 34, '2021-08-31 13:00:00'),
       (46, 35, '2021-08-31 13:00:00'),
       (46, 36, '2021-08-31 13:00:00'),
       (47, 19, '2021-08-31 13:00:00'),
       (47, 21, '2021-08-31 13:00:00'),
       (47, 23, '2021-08-31 13:00:00'),
       (47, 25, '2021-08-31 13:00:00'),
       (47, 27, '2021-08-31 13:00:00'),
       (47, 28, '2021-08-31 13:00:00'),
       (47, 29, '2021-08-31 13:00:00'),
       (47, 30, '2021-08-31 13:00:00'),
       (47, 31, '2021-08-31 13:00:00'),
       (47, 32, '2021-08-31 13:00:00'),
       (47, 34, '2021-08-31 13:00:00'),
       (47, 35, '2021-08-31 13:00:00'),
       (47, 36, '2021-08-31 13:00:00'),
       (48, 20, '2021-08-31 13:00:00'),
       (48, 22, '2021-08-31 13:00:00'),
       (48, 24, '2021-08-31 13:00:00'),
       (48, 26, '2021-08-31 13:00:00'),
       (48, 27, '2021-08-31 13:00:00'),
       (48, 28, '2021-08-31 13:00:00'),
       (48, 29, '2021-08-31 13:00:00'),
       (48, 30, '2021-08-31 13:00:00'),
       (48, 31, '2021-08-31 13:00:00'),
       (48, 33, '2021-08-31 13:00:00'),
       (48, 34, '2021-08-31 13:00:00'),
       (48, 35, '2021-08-31 13:00:00'),
       (48, 36, '2021-08-31 13:00:00'),
       (49, 19, '2021-08-31 13:00:00'),
       (49, 21, '2021-08-31 13:00:00'),
       (49, 23, '2021-08-31 13:00:00'),
       (49, 25, '2021-08-31 13:00:00'),
       (49, 27, '2021-08-31 13:00:00'),
       (49, 28, '2021-08-31 13:00:00'),
       (49, 29, '2021-08-31 13:00:00'),
       (49, 30, '2021-08-31 13:00:00'),
       (49, 31, '2021-08-31 13:00:00'),
       (49, 32, '2021-08-31 13:00:00'),
       (49, 34, '2021-08-31 13:00:00'),
       (49, 35, '2021-08-31 13:00:00'),
       (49, 36, '2021-08-31 13:00:00'),
       (50, 20, '2021-08-31 13:00:00'),
       (50, 22, '2021-08-31 13:00:00'),
       (50, 24, '2021-08-31 13:00:00'),
       (50, 26, '2021-08-31 13:00:00'),
       (50, 27, '2021-08-31 13:00:00'),
       (50, 28, '2021-08-31 13:00:00'),
       (50, 29, '2021-08-31 13:00:00'),
       (50, 30, '2021-08-31 13:00:00'),
       (50, 31, '2021-08-31 13:00:00'),
       (50, 33, '2021-08-31 13:00:00'),
       (50, 34, '2021-08-31 13:00:00'),
       (50, 35, '2021-08-31 13:00:00'),
       (50, 36, '2021-08-31 13:00:00'),
       (51, 19, '2021-08-31 13:00:00'),
       (51, 21, '2021-08-31 13:00:00'),
       (51, 23, '2021-08-31 13:00:00'),
       (51, 25, '2021-08-31 13:00:00'),
       (51, 27, '2021-08-31 13:00:00'),
       (51, 28, '2021-08-31 13:00:00'),
       (51, 29, '2021-08-31 13:00:00'),
       (51, 30, '2021-08-31 13:00:00'),
       (51, 31, '2021-08-31 13:00:00'),
       (51, 32, '2021-08-31 13:00:00'),
       (51, 34, '2021-08-31 13:00:00'),
       (51, 35, '2021-08-31 13:00:00'),
       (51, 36, '2021-08-31 13:00:00'),
       (52, 20, '2021-08-31 13:00:00'),
       (52, 22, '2021-08-31 13:00:00'),
       (52, 24, '2021-08-31 13:00:00'),
       (52, 26, '2021-08-31 13:00:00'),
       (52, 27, '2021-08-31 13:00:00'),
       (52, 28, '2021-08-31 13:00:00'),
       (52, 29, '2021-08-31 13:00:00'),
       (52, 30, '2021-08-31 13:00:00'),
       (52, 31, '2021-08-31 13:00:00'),
       (52, 33, '2021-08-31 13:00:00'),
       (52, 34, '2021-08-31 13:00:00'),
       (52, 35, '2021-08-31 13:00:00'),
       (52, 36, '2021-08-31 13:00:00'),
       (53, 19, '2021-08-31 13:00:00'),
       (53, 21, '2021-08-31 13:00:00'),
       (53, 23, '2021-08-31 13:00:00'),
       (53, 25, '2021-08-31 13:00:00'),
       (53, 27, '2021-08-31 13:00:00'),
       (53, 28, '2021-08-31 13:00:00'),
       (53, 29, '2021-08-31 13:00:00'),
       (53, 30, '2021-08-31 13:00:00'),
       (53, 31, '2021-08-31 13:00:00'),
       (53, 32, '2021-08-31 13:00:00'),
       (53, 34, '2021-08-31 13:00:00'),
       (53, 35, '2021-08-31 13:00:00'),
       (53, 36, '2021-08-31 13:00:00'),
       (54, 20, '2021-08-31 13:00:00'),
       (54, 22, '2021-08-31 13:00:00'),
       (54, 24, '2021-08-31 13:00:00'),
       (54, 26, '2021-08-31 13:00:00'),
       (54, 27, '2021-08-31 13:00:00'),
       (54, 28, '2021-08-31 13:00:00'),
       (54, 29, '2021-08-31 13:00:00'),
       (54, 30, '2021-08-31 13:00:00'),
       (54, 31, '2021-08-31 13:00:00'),
       (54, 33, '2021-08-31 13:00:00'),
       (54, 34, '2021-08-31 13:00:00'),
       (54, 35, '2021-08-31 13:00:00'),
       (54, 36, '2021-08-31 13:00:00'),
       (55, 19, '2021-08-31 13:00:00'),
       (55, 21, '2021-08-31 13:00:00'),
       (55, 23, '2021-08-31 13:00:00'),
       (55, 25, '2021-08-31 13:00:00'),
       (55, 27, '2021-08-31 13:00:00'),
       (55, 28, '2021-08-31 13:00:00'),
       (55, 29, '2021-08-31 13:00:00'),
       (55, 30, '2021-08-31 13:00:00'),
       (55, 31, '2021-08-31 13:00:00'),
       (55, 32, '2021-08-31 13:00:00'),
       (55, 34, '2021-08-31 13:00:00'),
       (55, 35, '2021-08-31 13:00:00'),
       (55, 36, '2021-08-31 13:00:00'),
       (56, 20, '2021-08-31 13:00:00'),
       (56, 22, '2021-08-31 13:00:00'),
       (56, 24, '2021-08-31 13:00:00'),
       (56, 26, '2021-08-31 13:00:00'),
       (56, 27, '2021-08-31 13:00:00'),
       (56, 28, '2021-08-31 13:00:00'),
       (56, 29, '2021-08-31 13:00:00'),
       (56, 30, '2021-08-31 13:00:00'),
       (56, 31, '2021-08-31 13:00:00'),
       (56, 33, '2021-08-31 13:00:00'),
       (56, 34, '2021-08-31 13:00:00'),
       (56, 35, '2021-08-31 13:00:00'),
       (56, 36, '2021-08-31 13:00:00'),
       (57, 19, '2021-08-31 13:00:00'),
       (57, 21, '2021-08-31 13:00:00'),
       (57, 23, '2021-08-31 13:00:00'),
       (57, 25, '2021-08-31 13:00:00'),
       (57, 27, '2021-08-31 13:00:00'),
       (57, 28, '2021-08-31 13:00:00'),
       (57, 29, '2021-08-31 13:00:00'),
       (57, 30, '2021-08-31 13:00:00'),
       (57, 31, '2021-08-31 13:00:00'),
       (57, 32, '2021-08-31 13:00:00'),
       (57, 34, '2021-08-31 13:00:00'),
       (57, 35, '2021-08-31 13:00:00'),
       (57, 36, '2021-08-31 13:00:00'),
       (58, 20, '2021-08-31 13:00:00'),
       (58, 22, '2021-08-31 13:00:00'),
       (58, 24, '2021-08-31 13:00:00'),
       (58, 26, '2021-08-31 13:00:00'),
       (58, 27, '2021-08-31 13:00:00'),
       (58, 28, '2021-08-31 13:00:00'),
       (58, 29, '2021-08-31 13:00:00'),
       (58, 30, '2021-08-31 13:00:00'),
       (58, 31, '2021-08-31 13:00:00'),
       (58, 33, '2021-08-31 13:00:00'),
       (58, 34, '2021-08-31 13:00:00'),
       (58, 35, '2021-08-31 13:00:00'),
       (58, 36, '2021-08-31 13:00:00'),
       (59, 19, '2021-08-31 13:00:00'),
       (59, 21, '2021-08-31 13:00:00'),
       (59, 23, '2021-08-31 13:00:00'),
       (59, 25, '2021-08-31 13:00:00'),
       (59, 27, '2021-08-31 13:00:00'),
       (59, 28, '2021-08-31 13:00:00'),
       (59, 29, '2021-08-31 13:00:00'),
       (59, 30, '2021-08-31 13:00:00'),
       (59, 31, '2021-08-31 13:00:00'),
       (59, 32, '2021-08-31 13:00:00'),
       (59, 34, '2021-08-31 13:00:00'),
       (59, 35, '2021-08-31 13:00:00'),
       (59, 36, '2021-08-31 13:00:00'),
       (60, 20, '2021-08-31 13:00:00'),
       (60, 22, '2021-08-31 13:00:00'),
       (60, 24, '2021-08-31 13:00:00'),
       (60, 26, '2021-08-31 13:00:00'),
       (60, 27, '2021-08-31 13:00:00'),
       (60, 28, '2021-08-31 13:00:00'),
       (60, 29, '2021-08-31 13:00:00'),
       (60, 30, '2021-08-31 13:00:00'),
       (60, 31, '2021-08-31 13:00:00'),
       (60, 33, '2021-08-31 13:00:00'),
       (60, 34, '2021-08-31 13:00:00'),
       (60, 35, '2021-08-31 13:00:00'),
       (60, 36, '2021-08-31 13:00:00'),
       (61, 37, '2021-08-31 13:00:00'),
       (61, 39, '2021-08-31 13:00:00'),
       (61, 41, '2021-08-31 13:00:00'),
       (61, 43, '2021-08-31 13:00:00'),
       (61, 45, '2021-08-31 13:00:00'),
       (61, 46, '2021-08-31 13:00:00'),
       (61, 47, '2021-08-31 13:00:00'),
       (61, 48, '2021-08-31 13:00:00'),
       (61, 49, '2021-08-31 13:00:00'),
       (61, 50, '2021-08-31 13:00:00'),
       (61, 52, '2021-08-31 13:00:00'),
       (61, 53, '2021-08-31 13:00:00'),
       (62, 38, '2021-08-31 13:00:00'),
       (62, 40, '2021-08-31 13:00:00'),
       (62, 42, '2021-08-31 13:00:00'),
       (62, 44, '2021-08-31 13:00:00'),
       (62, 45, '2021-08-31 13:00:00'),
       (62, 46, '2021-08-31 13:00:00'),
       (62, 47, '2021-08-31 13:00:00'),
       (62, 48, '2021-08-31 13:00:00'),
       (62, 49, '2021-08-31 13:00:00'),
       (62, 51, '2021-08-31 13:00:00'),
       (62, 52, '2021-08-31 13:00:00'),
       (62, 53, '2021-08-31 13:00:00'),
       (63, 37, '2021-08-31 13:00:00'),
       (63, 39, '2021-08-31 13:00:00'),
       (63, 41, '2021-08-31 13:00:00'),
       (63, 43, '2021-08-31 13:00:00'),
       (63, 45, '2021-08-31 13:00:00'),
       (63, 46, '2021-08-31 13:00:00'),
       (63, 47, '2021-08-31 13:00:00'),
       (63, 48, '2021-08-31 13:00:00'),
       (63, 49, '2021-08-31 13:00:00'),
       (63, 50, '2021-08-31 13:00:00'),
       (63, 52, '2021-08-31 13:00:00'),
       (63, 53, '2021-08-31 13:00:00'),
       (64, 38, '2021-08-31 13:00:00'),
       (64, 40, '2021-08-31 13:00:00'),
       (64, 42, '2021-08-31 13:00:00'),
       (64, 44, '2021-08-31 13:00:00'),
       (64, 45, '2021-08-31 13:00:00'),
       (64, 46, '2021-08-31 13:00:00'),
       (64, 47, '2021-08-31 13:00:00'),
       (64, 48, '2021-08-31 13:00:00'),
       (64, 49, '2021-08-31 13:00:00'),
       (64, 51, '2021-08-31 13:00:00'),
       (64, 52, '2021-08-31 13:00:00'),
       (64, 53, '2021-08-31 13:00:00'),
       (65, 37, '2021-08-31 13:00:00'),
       (65, 39, '2021-08-31 13:00:00'),
       (65, 41, '2021-08-31 13:00:00'),
       (65, 43, '2021-08-31 13:00:00'),
       (65, 45, '2021-08-31 13:00:00'),
       (65, 46, '2021-08-31 13:00:00'),
       (65, 47, '2021-08-31 13:00:00'),
       (65, 48, '2021-08-31 13:00:00'),
       (65, 49, '2021-08-31 13:00:00'),
       (65, 50, '2021-08-31 13:00:00'),
       (65, 52, '2021-08-31 13:00:00'),
       (65, 53, '2021-08-31 13:00:00'),
       (66, 38, '2021-08-31 13:00:00'),
       (66, 40, '2021-08-31 13:00:00'),
       (66, 42, '2021-08-31 13:00:00'),
       (66, 44, '2021-08-31 13:00:00'),
       (66, 45, '2021-08-31 13:00:00'),
       (66, 46, '2021-08-31 13:00:00'),
       (66, 47, '2021-08-31 13:00:00'),
       (66, 48, '2021-08-31 13:00:00'),
       (66, 49, '2021-08-31 13:00:00'),
       (66, 51, '2021-08-31 13:00:00'),
       (66, 52, '2021-08-31 13:00:00'),
       (66, 53, '2021-08-31 13:00:00'),
       (67, 37, '2021-08-31 13:00:00'),
       (67, 39, '2021-08-31 13:00:00'),
       (67, 41, '2021-08-31 13:00:00'),
       (67, 43, '2021-08-31 13:00:00'),
       (67, 45, '2021-08-31 13:00:00'),
       (67, 46, '2021-08-31 13:00:00'),
       (67, 47, '2021-08-31 13:00:00'),
       (67, 48, '2021-08-31 13:00:00'),
       (67, 49, '2021-08-31 13:00:00'),
       (67, 50, '2021-08-31 13:00:00'),
       (67, 52, '2021-08-31 13:00:00'),
       (67, 53, '2021-08-31 13:00:00'),
       (68, 38, '2021-08-31 13:00:00'),
       (68, 40, '2021-08-31 13:00:00'),
       (68, 42, '2021-08-31 13:00:00'),
       (68, 44, '2021-08-31 13:00:00'),
       (68, 45, '2021-08-31 13:00:00'),
       (68, 46, '2021-08-31 13:00:00'),
       (68, 47, '2021-08-31 13:00:00'),
       (68, 48, '2021-08-31 13:00:00'),
       (68, 49, '2021-08-31 13:00:00'),
       (68, 51, '2021-08-31 13:00:00'),
       (68, 52, '2021-08-31 13:00:00'),
       (68, 53, '2021-08-31 13:00:00'),
       (69, 37, '2021-08-31 13:00:00'),
       (69, 39, '2021-08-31 13:00:00'),
       (69, 41, '2021-08-31 13:00:00'),
       (69, 43, '2021-08-31 13:00:00'),
       (69, 45, '2021-08-31 13:00:00'),
       (69, 46, '2021-08-31 13:00:00'),
       (69, 47, '2021-08-31 13:00:00'),
       (69, 48, '2021-08-31 13:00:00'),
       (69, 49, '2021-08-31 13:00:00'),
       (69, 50, '2021-08-31 13:00:00'),
       (69, 52, '2021-08-31 13:00:00'),
       (69, 53, '2021-08-31 13:00:00'),
       (70, 38, '2021-08-31 13:00:00'),
       (70, 40, '2021-08-31 13:00:00'),
       (70, 42, '2021-08-31 13:00:00'),
       (70, 44, '2021-08-31 13:00:00'),
       (70, 45, '2021-08-31 13:00:00'),
       (70, 46, '2021-08-31 13:00:00'),
       (70, 47, '2021-08-31 13:00:00'),
       (70, 48, '2021-08-31 13:00:00'),
       (70, 49, '2021-08-31 13:00:00'),
       (70, 51, '2021-08-31 13:00:00'),
       (70, 52, '2021-08-31 13:00:00'),
       (70, 53, '2021-08-31 13:00:00'),
       (71, 37, '2021-08-31 13:00:00'),
       (71, 39, '2021-08-31 13:00:00'),
       (71, 41, '2021-08-31 13:00:00'),
       (71, 43, '2021-08-31 13:00:00'),
       (71, 45, '2021-08-31 13:00:00'),
       (71, 46, '2021-08-31 13:00:00'),
       (71, 47, '2021-08-31 13:00:00'),
       (71, 48, '2021-08-31 13:00:00'),
       (71, 49, '2021-08-31 13:00:00'),
       (71, 50, '2021-08-31 13:00:00'),
       (71, 52, '2021-08-31 13:00:00'),
       (71, 53, '2021-08-31 13:00:00'),
       (72, 38, '2021-08-31 13:00:00'),
       (72, 40, '2021-08-31 13:00:00'),
       (72, 42, '2021-08-31 13:00:00'),
       (72, 44, '2021-08-31 13:00:00'),
       (72, 45, '2021-08-31 13:00:00'),
       (72, 46, '2021-08-31 13:00:00'),
       (72, 47, '2021-08-31 13:00:00'),
       (72, 48, '2021-08-31 13:00:00'),
       (72, 49, '2021-08-31 13:00:00'),
       (72, 51, '2021-08-31 13:00:00'),
       (72, 52, '2021-08-31 13:00:00'),
       (72, 53, '2021-08-31 13:00:00'),
       (73, 37, '2021-08-31 13:00:00'),
       (73, 39, '2021-08-31 13:00:00'),
       (73, 41, '2021-08-31 13:00:00'),
       (73, 43, '2021-08-31 13:00:00'),
       (73, 45, '2021-08-31 13:00:00'),
       (73, 46, '2021-08-31 13:00:00'),
       (73, 47, '2021-08-31 13:00:00'),
       (73, 48, '2021-08-31 13:00:00'),
       (73, 49, '2021-08-31 13:00:00'),
       (73, 50, '2021-08-31 13:00:00'),
       (73, 52, '2021-08-31 13:00:00'),
       (73, 53, '2021-08-31 13:00:00'),
       (74, 38, '2021-08-31 13:00:00'),
       (74, 40, '2021-08-31 13:00:00'),
       (74, 42, '2021-08-31 13:00:00'),
       (74, 44, '2021-08-31 13:00:00'),
       (74, 45, '2021-08-31 13:00:00'),
       (74, 46, '2021-08-31 13:00:00'),
       (74, 47, '2021-08-31 13:00:00'),
       (74, 48, '2021-08-31 13:00:00'),
       (74, 49, '2021-08-31 13:00:00'),
       (74, 51, '2021-08-31 13:00:00'),
       (74, 52, '2021-08-31 13:00:00'),
       (74, 53, '2021-08-31 13:00:00'),
       (75, 37, '2021-08-31 13:00:00'),
       (75, 39, '2021-08-31 13:00:00'),
       (75, 41, '2021-08-31 13:00:00'),
       (75, 43, '2021-08-31 13:00:00'),
       (75, 45, '2021-08-31 13:00:00'),
       (75, 46, '2021-08-31 13:00:00'),
       (75, 47, '2021-08-31 13:00:00'),
       (75, 48, '2021-08-31 13:00:00'),
       (75, 49, '2021-08-31 13:00:00'),
       (75, 50, '2021-08-31 13:00:00'),
       (75, 52, '2021-08-31 13:00:00'),
       (75, 53, '2021-08-31 13:00:00'),
       (76, 38, '2021-08-31 13:00:00'),
       (76, 40, '2021-08-31 13:00:00'),
       (76, 42, '2021-08-31 13:00:00'),
       (76, 44, '2021-08-31 13:00:00'),
       (76, 45, '2021-08-31 13:00:00'),
       (76, 46, '2021-08-31 13:00:00'),
       (76, 47, '2021-08-31 13:00:00'),
       (76, 48, '2021-08-31 13:00:00'),
       (76, 49, '2021-08-31 13:00:00'),
       (76, 51, '2021-08-31 13:00:00'),
       (76, 52, '2021-08-31 13:00:00'),
       (76, 53, '2021-08-31 13:00:00'),
       (77, 37, '2021-08-31 13:00:00'),
       (77, 39, '2021-08-31 13:00:00'),
       (77, 41, '2021-08-31 13:00:00'),
       (77, 43, '2021-08-31 13:00:00'),
       (77, 45, '2021-08-31 13:00:00'),
       (77, 46, '2021-08-31 13:00:00'),
       (77, 47, '2021-08-31 13:00:00'),
       (77, 48, '2021-08-31 13:00:00'),
       (77, 49, '2021-08-31 13:00:00'),
       (77, 50, '2021-08-31 13:00:00'),
       (77, 52, '2021-08-31 13:00:00'),
       (77, 53, '2021-08-31 13:00:00'),
       (78, 38, '2021-08-31 13:00:00'),
       (78, 40, '2021-08-31 13:00:00'),
       (78, 42, '2021-08-31 13:00:00'),
       (78, 44, '2021-08-31 13:00:00'),
       (78, 45, '2021-08-31 13:00:00'),
       (78, 46, '2021-08-31 13:00:00'),
       (78, 47, '2021-08-31 13:00:00'),
       (78, 48, '2021-08-31 13:00:00'),
       (78, 49, '2021-08-31 13:00:00'),
       (78, 51, '2021-08-31 13:00:00'),
       (78, 52, '2021-08-31 13:00:00'),
       (78, 53, '2021-08-31 13:00:00'),
       (79, 37, '2021-08-31 13:00:00'),
       (79, 39, '2021-08-31 13:00:00'),
       (79, 41, '2021-08-31 13:00:00'),
       (79, 43, '2021-08-31 13:00:00'),
       (79, 45, '2021-08-31 13:00:00'),
       (79, 46, '2021-08-31 13:00:00'),
       (79, 47, '2021-08-31 13:00:00'),
       (79, 48, '2021-08-31 13:00:00'),
       (79, 49, '2021-08-31 13:00:00'),
       (79, 50, '2021-08-31 13:00:00'),
       (79, 52, '2021-08-31 13:00:00'),
       (79, 53, '2021-08-31 13:00:00'),
       (80, 38, '2021-08-31 13:00:00'),
       (80, 40, '2021-08-31 13:00:00'),
       (80, 42, '2021-08-31 13:00:00'),
       (80, 44, '2021-08-31 13:00:00'),
       (80, 45, '2021-08-31 13:00:00'),
       (80, 46, '2021-08-31 13:00:00'),
       (80, 47, '2021-08-31 13:00:00'),
       (80, 48, '2021-08-31 13:00:00'),
       (80, 49, '2021-08-31 13:00:00'),
       (80, 51, '2021-08-31 13:00:00'),
       (80, 52, '2021-08-31 13:00:00'),
       (80, 53, '2021-08-31 13:00:00'),
       (81, 37, '2021-08-31 13:00:00'),
       (81, 39, '2021-08-31 13:00:00'),
       (81, 41, '2021-08-31 13:00:00'),
       (81, 43, '2021-08-31 13:00:00'),
       (81, 45, '2021-08-31 13:00:00'),
       (81, 46, '2021-08-31 13:00:00'),
       (81, 47, '2021-08-31 13:00:00'),
       (81, 48, '2021-08-31 13:00:00'),
       (81, 49, '2021-08-31 13:00:00'),
       (81, 50, '2021-08-31 13:00:00'),
       (81, 52, '2021-08-31 13:00:00'),
       (81, 53, '2021-08-31 13:00:00'),
       (82, 38, '2021-08-31 13:00:00'),
       (82, 40, '2021-08-31 13:00:00'),
       (82, 42, '2021-08-31 13:00:00'),
       (82, 44, '2021-08-31 13:00:00'),
       (82, 45, '2021-08-31 13:00:00'),
       (82, 46, '2021-08-31 13:00:00'),
       (82, 47, '2021-08-31 13:00:00'),
       (82, 48, '2021-08-31 13:00:00'),
       (82, 49, '2021-08-31 13:00:00'),
       (82, 51, '2021-08-31 13:00:00'),
       (82, 52, '2021-08-31 13:00:00'),
       (82, 53, '2021-08-31 13:00:00'),
       (83, 37, '2021-08-31 13:00:00'),
       (83, 39, '2021-08-31 13:00:00'),
       (83, 41, '2021-08-31 13:00:00'),
       (83, 43, '2021-08-31 13:00:00'),
       (83, 45, '2021-08-31 13:00:00'),
       (83, 46, '2021-08-31 13:00:00'),
       (83, 47, '2021-08-31 13:00:00'),
       (83, 48, '2021-08-31 13:00:00'),
       (83, 49, '2021-08-31 13:00:00'),
       (83, 50, '2021-08-31 13:00:00'),
       (83, 52, '2021-08-31 13:00:00'),
       (83, 53, '2021-08-31 13:00:00'),
       (84, 38, '2021-08-31 13:00:00'),
       (84, 40, '2021-08-31 13:00:00'),
       (84, 42, '2021-08-31 13:00:00'),
       (84, 44, '2021-08-31 13:00:00'),
       (84, 45, '2021-08-31 13:00:00'),
       (84, 46, '2021-08-31 13:00:00'),
       (84, 47, '2021-08-31 13:00:00'),
       (84, 48, '2021-08-31 13:00:00'),
       (84, 49, '2021-08-31 13:00:00'),
       (84, 51, '2021-08-31 13:00:00'),
       (84, 52, '2021-08-31 13:00:00'),
       (84, 53, '2021-08-31 13:00:00'),
       (85, 37, '2021-08-31 13:00:00'),
       (85, 39, '2021-08-31 13:00:00'),
       (85, 41, '2021-08-31 13:00:00'),
       (85, 43, '2021-08-31 13:00:00'),
       (85, 45, '2021-08-31 13:00:00'),
       (85, 46, '2021-08-31 13:00:00'),
       (85, 47, '2021-08-31 13:00:00'),
       (85, 48, '2021-08-31 13:00:00'),
       (85, 49, '2021-08-31 13:00:00'),
       (85, 50, '2021-08-31 13:00:00'),
       (85, 52, '2021-08-31 13:00:00'),
       (85, 53, '2021-08-31 13:00:00'),
       (86, 38, '2021-08-31 13:00:00'),
       (86, 40, '2021-08-31 13:00:00'),
       (86, 42, '2021-08-31 13:00:00'),
       (86, 44, '2021-08-31 13:00:00'),
       (86, 45, '2021-08-31 13:00:00'),
       (86, 46, '2021-08-31 13:00:00'),
       (86, 47, '2021-08-31 13:00:00'),
       (86, 48, '2021-08-31 13:00:00'),
       (86, 49, '2021-08-31 13:00:00'),
       (86, 51, '2021-08-31 13:00:00'),
       (86, 52, '2021-08-31 13:00:00'),
       (86, 53, '2021-08-31 13:00:00'),
       (87, 37, '2021-08-31 13:00:00'),
       (87, 39, '2021-08-31 13:00:00'),
       (87, 41, '2021-08-31 13:00:00'),
       (87, 43, '2021-08-31 13:00:00'),
       (87, 45, '2021-08-31 13:00:00'),
       (87, 46, '2021-08-31 13:00:00'),
       (87, 47, '2021-08-31 13:00:00'),
       (87, 48, '2021-08-31 13:00:00'),
       (87, 49, '2021-08-31 13:00:00'),
       (87, 50, '2021-08-31 13:00:00'),
       (87, 52, '2021-08-31 13:00:00'),
       (87, 53, '2021-08-31 13:00:00'),
       (88, 38, '2021-08-31 13:00:00'),
       (88, 40, '2021-08-31 13:00:00'),
       (88, 42, '2021-08-31 13:00:00'),
       (88, 44, '2021-08-31 13:00:00'),
       (88, 45, '2021-08-31 13:00:00'),
       (88, 46, '2021-08-31 13:00:00'),
       (88, 47, '2021-08-31 13:00:00'),
       (88, 48, '2021-08-31 13:00:00'),
       (88, 49, '2021-08-31 13:00:00'),
       (88, 51, '2021-08-31 13:00:00'),
       (88, 52, '2021-08-31 13:00:00'),
       (88, 53, '2021-08-31 13:00:00'),
       (89, 37, '2021-08-31 13:00:00'),
       (89, 39, '2021-08-31 13:00:00'),
       (89, 41, '2021-08-31 13:00:00'),
       (89, 43, '2021-08-31 13:00:00'),
       (89, 45, '2021-08-31 13:00:00'),
       (89, 46, '2021-08-31 13:00:00'),
       (89, 47, '2021-08-31 13:00:00'),
       (89, 48, '2021-08-31 13:00:00'),
       (89, 49, '2021-08-31 13:00:00'),
       (89, 50, '2021-08-31 13:00:00'),
       (89, 52, '2021-08-31 13:00:00'),
       (89, 53, '2021-08-31 13:00:00'),
       (90, 38, '2021-08-31 13:00:00'),
       (90, 40, '2021-08-31 13:00:00'),
       (90, 42, '2021-08-31 13:00:00'),
       (90, 44, '2021-08-31 13:00:00'),
       (90, 45, '2021-08-31 13:00:00'),
       (90, 46, '2021-08-31 13:00:00'),
       (90, 47, '2021-08-31 13:00:00'),
       (90, 48, '2021-08-31 13:00:00'),
       (90, 49, '2021-08-31 13:00:00'),
       (90, 51, '2021-08-31 13:00:00'),
       (90, 52, '2021-08-31 13:00:00'),
       (90, 53, '2021-08-31 13:00:00'),
       (91, 54, '2021-08-31 13:00:00'),
       (91, 56, '2021-08-31 13:00:00'),
       (91, 58, '2021-08-31 13:00:00'),
       (91, 60, '2021-08-31 13:00:00'),
       (91, 62, '2021-08-31 13:00:00'),
       (91, 63, '2021-08-31 13:00:00'),
       (91, 64, '2021-08-31 13:00:00'),
       (91, 65, '2021-08-31 13:00:00'),
       (91, 66, '2021-08-31 13:00:00'),
       (91, 67, '2021-08-31 13:00:00'),
       (91, 69, '2021-08-31 13:00:00'),
       (91, 70, '2021-08-31 13:00:00'),
       (92, 55, '2021-08-31 13:00:00'),
       (92, 57, '2021-08-31 13:00:00'),
       (92, 59, '2021-08-31 13:00:00'),
       (92, 61, '2021-08-31 13:00:00'),
       (92, 62, '2021-08-31 13:00:00'),
       (92, 63, '2021-08-31 13:00:00'),
       (92, 64, '2021-08-31 13:00:00'),
       (92, 65, '2021-08-31 13:00:00'),
       (92, 66, '2021-08-31 13:00:00'),
       (92, 68, '2021-08-31 13:00:00'),
       (92, 69, '2021-08-31 13:00:00'),
       (92, 70, '2021-08-31 13:00:00'),
       (93, 54, '2021-08-31 13:00:00'),
       (93, 56, '2021-08-31 13:00:00'),
       (93, 58, '2021-08-31 13:00:00'),
       (93, 60, '2021-08-31 13:00:00'),
       (93, 62, '2021-08-31 13:00:00'),
       (93, 63, '2021-08-31 13:00:00'),
       (93, 64, '2021-08-31 13:00:00'),
       (93, 65, '2021-08-31 13:00:00'),
       (93, 66, '2021-08-31 13:00:00'),
       (93, 67, '2021-08-31 13:00:00'),
       (93, 69, '2021-08-31 13:00:00'),
       (93, 70, '2021-08-31 13:00:00'),
       (94, 55, '2021-08-31 13:00:00'),
       (94, 57, '2021-08-31 13:00:00'),
       (94, 59, '2021-08-31 13:00:00'),
       (94, 61, '2021-08-31 13:00:00'),
       (94, 62, '2021-08-31 13:00:00'),
       (94, 63, '2021-08-31 13:00:00'),
       (94, 64, '2021-08-31 13:00:00'),
       (94, 65, '2021-08-31 13:00:00'),
       (94, 66, '2021-08-31 13:00:00'),
       (94, 68, '2021-08-31 13:00:00'),
       (94, 69, '2021-08-31 13:00:00'),
       (94, 70, '2021-08-31 13:00:00'),
       (95, 54, '2021-08-31 13:00:00'),
       (95, 56, '2021-08-31 13:00:00'),
       (95, 58, '2021-08-31 13:00:00'),
       (95, 60, '2021-08-31 13:00:00'),
       (95, 62, '2021-08-31 13:00:00'),
       (95, 63, '2021-08-31 13:00:00'),
       (95, 64, '2021-08-31 13:00:00'),
       (95, 65, '2021-08-31 13:00:00'),
       (95, 66, '2021-08-31 13:00:00'),
       (95, 67, '2021-08-31 13:00:00'),
       (95, 69, '2021-08-31 13:00:00'),
       (95, 70, '2021-08-31 13:00:00'),
       (96, 55, '2021-08-31 13:00:00'),
       (96, 57, '2021-08-31 13:00:00'),
       (96, 59, '2021-08-31 13:00:00'),
       (96, 61, '2021-08-31 13:00:00'),
       (96, 62, '2021-08-31 13:00:00'),
       (96, 63, '2021-08-31 13:00:00'),
       (96, 64, '2021-08-31 13:00:00'),
       (96, 65, '2021-08-31 13:00:00'),
       (96, 66, '2021-08-31 13:00:00'),
       (96, 68, '2021-08-31 13:00:00'),
       (96, 69, '2021-08-31 13:00:00'),
       (96, 70, '2021-08-31 13:00:00'),
       (97, 54, '2021-08-31 13:00:00'),
       (97, 56, '2021-08-31 13:00:00'),
       (97, 58, '2021-08-31 13:00:00'),
       (97, 60, '2021-08-31 13:00:00'),
       (97, 62, '2021-08-31 13:00:00'),
       (97, 63, '2021-08-31 13:00:00'),
       (97, 64, '2021-08-31 13:00:00'),
       (97, 65, '2021-08-31 13:00:00'),
       (97, 66, '2021-08-31 13:00:00'),
       (97, 67, '2021-08-31 13:00:00'),
       (97, 69, '2021-08-31 13:00:00'),
       (97, 70, '2021-08-31 13:00:00'),
       (98, 55, '2021-08-31 13:00:00'),
       (98, 57, '2021-08-31 13:00:00'),
       (98, 59, '2021-08-31 13:00:00'),
       (98, 61, '2021-08-31 13:00:00'),
       (98, 62, '2021-08-31 13:00:00'),
       (98, 63, '2021-08-31 13:00:00'),
       (98, 64, '2021-08-31 13:00:00'),
       (98, 65, '2021-08-31 13:00:00'),
       (98, 66, '2021-08-31 13:00:00'),
       (98, 68, '2021-08-31 13:00:00'),
       (98, 69, '2021-08-31 13:00:00'),
       (98, 70, '2021-08-31 13:00:00'),
       (99, 54, '2021-08-31 13:00:00'),
       (99, 56, '2021-08-31 13:00:00'),
       (99, 58, '2021-08-31 13:00:00'),
       (99, 60, '2021-08-31 13:00:00'),
       (99, 62, '2021-08-31 13:00:00'),
       (99, 63, '2021-08-31 13:00:00'),
       (99, 64, '2021-08-31 13:00:00'),
       (99, 65, '2021-08-31 13:00:00'),
       (99, 66, '2021-08-31 13:00:00'),
       (99, 67, '2021-08-31 13:00:00'),
       (99, 69, '2021-08-31 13:00:00'),
       (99, 70, '2021-08-31 13:00:00'),
       (100, 55, '2021-08-31 13:00:00'),
       (100, 57, '2021-08-31 13:00:00'),
       (100, 59, '2021-08-31 13:00:00'),
       (100, 61, '2021-08-31 13:00:00'),
       (100, 62, '2021-08-31 13:00:00'),
       (100, 63, '2021-08-31 13:00:00'),
       (100, 64, '2021-08-31 13:00:00'),
       (100, 65, '2021-08-31 13:00:00'),
       (100, 66, '2021-08-31 13:00:00'),
       (100, 68, '2021-08-31 13:00:00'),
       (100, 69, '2021-08-31 13:00:00'),
       (100, 70, '2021-08-31 13:00:00'),
       (101, 54, '2021-08-31 13:00:00'),
       (101, 56, '2021-08-31 13:00:00'),
       (101, 58, '2021-08-31 13:00:00'),
       (101, 60, '2021-08-31 13:00:00'),
       (101, 62, '2021-08-31 13:00:00'),
       (101, 63, '2021-08-31 13:00:00'),
       (101, 64, '2021-08-31 13:00:00'),
       (101, 65, '2021-08-31 13:00:00'),
       (101, 66, '2021-08-31 13:00:00'),
       (101, 67, '2021-08-31 13:00:00'),
       (101, 69, '2021-08-31 13:00:00'),
       (101, 70, '2021-08-31 13:00:00'),
       (102, 55, '2021-08-31 13:00:00'),
       (102, 57, '2021-08-31 13:00:00'),
       (102, 59, '2021-08-31 13:00:00'),
       (102, 61, '2021-08-31 13:00:00'),
       (102, 62, '2021-08-31 13:00:00'),
       (102, 63, '2021-08-31 13:00:00'),
       (102, 64, '2021-08-31 13:00:00'),
       (102, 65, '2021-08-31 13:00:00'),
       (102, 66, '2021-08-31 13:00:00'),
       (102, 68, '2021-08-31 13:00:00'),
       (102, 69, '2021-08-31 13:00:00'),
       (102, 70, '2021-08-31 13:00:00'),
       (103, 54, '2021-08-31 13:00:00'),
       (103, 56, '2021-08-31 13:00:00'),
       (103, 58, '2021-08-31 13:00:00'),
       (103, 60, '2021-08-31 13:00:00'),
       (103, 62, '2021-08-31 13:00:00'),
       (103, 63, '2021-08-31 13:00:00'),
       (103, 64, '2021-08-31 13:00:00'),
       (103, 65, '2021-08-31 13:00:00'),
       (103, 66, '2021-08-31 13:00:00'),
       (103, 67, '2021-08-31 13:00:00'),
       (103, 69, '2021-08-31 13:00:00'),
       (103, 70, '2021-08-31 13:00:00'),
       (104, 55, '2021-08-31 13:00:00'),
       (104, 57, '2021-08-31 13:00:00'),
       (104, 59, '2021-08-31 13:00:00'),
       (104, 61, '2021-08-31 13:00:00'),
       (104, 62, '2021-08-31 13:00:00'),
       (104, 63, '2021-08-31 13:00:00'),
       (104, 64, '2021-08-31 13:00:00'),
       (104, 65, '2021-08-31 13:00:00'),
       (104, 66, '2021-08-31 13:00:00'),
       (104, 68, '2021-08-31 13:00:00'),
       (104, 69, '2021-08-31 13:00:00'),
       (104, 70, '2021-08-31 13:00:00'),
       (105, 54, '2021-08-31 13:00:00'),
       (105, 56, '2021-08-31 13:00:00'),
       (105, 58, '2021-08-31 13:00:00'),
       (105, 60, '2021-08-31 13:00:00'),
       (105, 62, '2021-08-31 13:00:00'),
       (105, 63, '2021-08-31 13:00:00'),
       (105, 64, '2021-08-31 13:00:00'),
       (105, 65, '2021-08-31 13:00:00'),
       (105, 66, '2021-08-31 13:00:00'),
       (105, 67, '2021-08-31 13:00:00'),
       (105, 69, '2021-08-31 13:00:00'),
       (105, 70, '2021-08-31 13:00:00'),
       (106, 55, '2021-08-31 13:00:00'),
       (106, 57, '2021-08-31 13:00:00'),
       (106, 59, '2021-08-31 13:00:00'),
       (106, 61, '2021-08-31 13:00:00'),
       (106, 62, '2021-08-31 13:00:00'),
       (106, 63, '2021-08-31 13:00:00'),
       (106, 64, '2021-08-31 13:00:00'),
       (106, 65, '2021-08-31 13:00:00'),
       (106, 66, '2021-08-31 13:00:00'),
       (106, 68, '2021-08-31 13:00:00'),
       (106, 69, '2021-08-31 13:00:00'),
       (106, 70, '2021-08-31 13:00:00'),
       (107, 54, '2021-08-31 13:00:00'),
       (107, 56, '2021-08-31 13:00:00'),
       (107, 58, '2021-08-31 13:00:00'),
       (107, 60, '2021-08-31 13:00:00'),
       (107, 62, '2021-08-31 13:00:00'),
       (107, 63, '2021-08-31 13:00:00'),
       (107, 64, '2021-08-31 13:00:00'),
       (107, 65, '2021-08-31 13:00:00'),
       (107, 66, '2021-08-31 13:00:00'),
       (107, 67, '2021-08-31 13:00:00'),
       (107, 69, '2021-08-31 13:00:00'),
       (107, 70, '2021-08-31 13:00:00'),
       (108, 55, '2021-08-31 13:00:00'),
       (108, 57, '2021-08-31 13:00:00'),
       (108, 59, '2021-08-31 13:00:00'),
       (108, 61, '2021-08-31 13:00:00'),
       (108, 62, '2021-08-31 13:00:00'),
       (108, 63, '2021-08-31 13:00:00'),
       (108, 64, '2021-08-31 13:00:00'),
       (108, 65, '2021-08-31 13:00:00'),
       (108, 66, '2021-08-31 13:00:00'),
       (108, 68, '2021-08-31 13:00:00'),
       (108, 69, '2021-08-31 13:00:00'),
       (108, 70, '2021-08-31 13:00:00'),
       (109, 54, '2021-08-31 13:00:00'),
       (109, 56, '2021-08-31 13:00:00'),
       (109, 58, '2021-08-31 13:00:00'),
       (109, 60, '2021-08-31 13:00:00'),
       (109, 62, '2021-08-31 13:00:00'),
       (109, 63, '2021-08-31 13:00:00'),
       (109, 64, '2021-08-31 13:00:00'),
       (109, 65, '2021-08-31 13:00:00'),
       (109, 66, '2021-08-31 13:00:00'),
       (109, 67, '2021-08-31 13:00:00'),
       (109, 69, '2021-08-31 13:00:00'),
       (109, 70, '2021-08-31 13:00:00'),
       (110, 55, '2021-08-31 13:00:00'),
       (110, 57, '2021-08-31 13:00:00'),
       (110, 59, '2021-08-31 13:00:00'),
       (110, 61, '2021-08-31 13:00:00'),
       (110, 62, '2021-08-31 13:00:00'),
       (110, 63, '2021-08-31 13:00:00'),
       (110, 64, '2021-08-31 13:00:00'),
       (110, 65, '2021-08-31 13:00:00'),
       (110, 66, '2021-08-31 13:00:00'),
       (110, 68, '2021-08-31 13:00:00'),
       (110, 69, '2021-08-31 13:00:00'),
       (110, 70, '2021-08-31 13:00:00'),
       (111, 54, '2021-08-31 13:00:00'),
       (111, 56, '2021-08-31 13:00:00'),
       (111, 58, '2021-08-31 13:00:00'),
       (111, 60, '2021-08-31 13:00:00'),
       (111, 62, '2021-08-31 13:00:00'),
       (111, 63, '2021-08-31 13:00:00'),
       (111, 64, '2021-08-31 13:00:00'),
       (111, 65, '2021-08-31 13:00:00'),
       (111, 66, '2021-08-31 13:00:00'),
       (111, 67, '2021-08-31 13:00:00'),
       (111, 69, '2021-08-31 13:00:00'),
       (111, 70, '2021-08-31 13:00:00'),
       (112, 55, '2021-08-31 13:00:00'),
       (112, 57, '2021-08-31 13:00:00'),
       (112, 59, '2021-08-31 13:00:00'),
       (112, 61, '2021-08-31 13:00:00'),
       (112, 62, '2021-08-31 13:00:00'),
       (112, 63, '2021-08-31 13:00:00'),
       (112, 64, '2021-08-31 13:00:00'),
       (112, 65, '2021-08-31 13:00:00'),
       (112, 66, '2021-08-31 13:00:00'),
       (112, 68, '2021-08-31 13:00:00'),
       (112, 69, '2021-08-31 13:00:00'),
       (112, 70, '2021-08-31 13:00:00'),
       (113, 54, '2021-08-31 13:00:00'),
       (113, 56, '2021-08-31 13:00:00'),
       (113, 58, '2021-08-31 13:00:00'),
       (113, 60, '2021-08-31 13:00:00'),
       (113, 62, '2021-08-31 13:00:00'),
       (113, 63, '2021-08-31 13:00:00'),
       (113, 64, '2021-08-31 13:00:00'),
       (113, 65, '2021-08-31 13:00:00'),
       (113, 66, '2021-08-31 13:00:00'),
       (113, 67, '2021-08-31 13:00:00'),
       (113, 69, '2021-08-31 13:00:00'),
       (113, 70, '2021-08-31 13:00:00'),
       (114, 55, '2021-08-31 13:00:00'),
       (114, 57, '2021-08-31 13:00:00'),
       (114, 59, '2021-08-31 13:00:00'),
       (114, 61, '2021-08-31 13:00:00'),
       (114, 62, '2021-08-31 13:00:00'),
       (114, 63, '2021-08-31 13:00:00'),
       (114, 64, '2021-08-31 13:00:00'),
       (114, 65, '2021-08-31 13:00:00'),
       (114, 66, '2021-08-31 13:00:00'),
       (114, 68, '2021-08-31 13:00:00'),
       (114, 69, '2021-08-31 13:00:00'),
       (114, 70, '2021-08-31 13:00:00'),
       (115, 54, '2021-08-31 13:00:00'),
       (115, 56, '2021-08-31 13:00:00'),
       (115, 58, '2021-08-31 13:00:00'),
       (115, 60, '2021-08-31 13:00:00'),
       (115, 62, '2021-08-31 13:00:00'),
       (115, 63, '2021-08-31 13:00:00'),
       (115, 64, '2021-08-31 13:00:00'),
       (115, 65, '2021-08-31 13:00:00'),
       (115, 66, '2021-08-31 13:00:00'),
       (115, 67, '2021-08-31 13:00:00'),
       (115, 69, '2021-08-31 13:00:00'),
       (115, 70, '2021-08-31 13:00:00'),
       (116, 55, '2021-08-31 13:00:00'),
       (116, 57, '2021-08-31 13:00:00'),
       (116, 59, '2021-08-31 13:00:00'),
       (116, 61, '2021-08-31 13:00:00'),
       (116, 62, '2021-08-31 13:00:00'),
       (116, 63, '2021-08-31 13:00:00'),
       (116, 64, '2021-08-31 13:00:00'),
       (116, 65, '2021-08-31 13:00:00'),
       (116, 66, '2021-08-31 13:00:00'),
       (116, 68, '2021-08-31 13:00:00'),
       (116, 69, '2021-08-31 13:00:00'),
       (116, 70, '2021-08-31 13:00:00'),
       (117, 54, '2021-08-31 13:00:00'),
       (117, 56, '2021-08-31 13:00:00'),
       (117, 58, '2021-08-31 13:00:00'),
       (117, 60, '2021-08-31 13:00:00'),
       (117, 62, '2021-08-31 13:00:00'),
       (117, 63, '2021-08-31 13:00:00'),
       (117, 64, '2021-08-31 13:00:00'),
       (117, 65, '2021-08-31 13:00:00'),
       (117, 66, '2021-08-31 13:00:00'),
       (117, 67, '2021-08-31 13:00:00'),
       (117, 69, '2021-08-31 13:00:00'),
       (117, 70, '2021-08-31 13:00:00'),
       (118, 55, '2021-08-31 13:00:00'),
       (118, 57, '2021-08-31 13:00:00'),
       (118, 59, '2021-08-31 13:00:00'),
       (118, 61, '2021-08-31 13:00:00'),
       (118, 62, '2021-08-31 13:00:00'),
       (118, 63, '2021-08-31 13:00:00'),
       (118, 64, '2021-08-31 13:00:00'),
       (118, 65, '2021-08-31 13:00:00'),
       (118, 66, '2021-08-31 13:00:00'),
       (118, 68, '2021-08-31 13:00:00'),
       (118, 69, '2021-08-31 13:00:00'),
       (118, 70, '2021-08-31 13:00:00'),
       (119, 54, '2021-08-31 13:00:00'),
       (119, 56, '2021-08-31 13:00:00'),
       (119, 58, '2021-08-31 13:00:00'),
       (119, 60, '2021-08-31 13:00:00'),
       (119, 62, '2021-08-31 13:00:00'),
       (119, 63, '2021-08-31 13:00:00'),
       (119, 64, '2021-08-31 13:00:00'),
       (119, 65, '2021-08-31 13:00:00'),
       (119, 66, '2021-08-31 13:00:00'),
       (119, 67, '2021-08-31 13:00:00'),
       (119, 69, '2021-08-31 13:00:00'),
       (119, 70, '2021-08-31 13:00:00'),
       (120, 55, '2021-08-31 13:00:00'),
       (120, 57, '2021-08-31 13:00:00'),
       (120, 59, '2021-08-31 13:00:00'),
       (120, 61, '2021-08-31 13:00:00'),
       (120, 62, '2021-08-31 13:00:00'),
       (120, 63, '2021-08-31 13:00:00'),
       (120, 64, '2021-08-31 13:00:00'),
       (120, 65, '2021-08-31 13:00:00'),
       (120, 66, '2021-08-31 13:00:00'),
       (120, 68, '2021-08-31 13:00:00'),
       (120, 69, '2021-08-31 13:00:00'),
       (120, 70, '2021-08-31 13:00:00');

insert into subject_to_class_certificate (class_id, subject_id)
values (1, 2),
       (1, 3),
       (1, 4),
       (1, 5),
       (1, 6),
       (1, 7),
       (1, 8),
       (1, 9),
       (1, 10),
       (1, 11),
       (1, 12),
       (1, 13),
       (2, 2),
       (2, 3),
       (2, 4),
       (2, 5),
       (2, 6),
       (2, 7),
       (2, 8),
       (2, 9),
       (2, 10),
       (2, 11),
       (2, 12),
       (2, 13),
       (3, 15),
       (3, 16),
       (3, 17),
       (3, 18),
       (3, 19),
       (3, 20),
       (3, 21),
       (3, 22),
       (3, 23),
       (3, 24),
       (3, 25),
       (4, 15),
       (4, 16),
       (4, 17),
       (4, 18),
       (4, 19),
       (4, 20),
       (4, 21),
       (4, 22),
       (4, 23),
       (4, 24),
       (4, 25);

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
       (1, 6, '2021-09-01 10:00:00'),
       (4, 6, '2021-09-01 10:00:00'),
       (5, 6, '2021-09-01 10:00:00'),
       (6, 6, '2021-09-01 10:00:00'),
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
       (4, 37, '2021-09-01 11:00:00');
*/
--data final block end


