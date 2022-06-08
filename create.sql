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


CREATE TABLE quarters
(
    begin_date date NOT NULL,
    end_date   date NOT NULL,
    quarter_id serial,

    PRIMARY KEY (quarter_id)
);

CREATE TABLE themes
(
    title          varchar(40)                 NOT NULL,
    subject_id     int REFERENCES subjects     NOT NULL,
    lessons_length integer                     NOT NULL,
    theme_order    integer                     NOT NULL,
    quarter_id     integer REFERENCES quarters NOT NULL,
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
    subject_id int REFERENCES subjects NOT NULL,
    class_id   int REFERENCES classes  NOT NULL,

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
    return query (SELECT groups_to_events.group_id
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

CREATE FUNCTION get_subject_of_schedule(schedule_history_id integer)
    RETURNS integer
AS
$$
begin
    return (SELECT subject_id
            FROM schedule_history
            WHERE schedule_history.schedule_history_id = get_subject_of_schedule.schedule_history_id);
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

CREATE FUNCTION is_in_certificate(subject_id integer, class_id integer)
    RETURNS boolean
AS
$$
begin
    return EXISTS(SELECT *
                  FROM subject_to_class_certificate
                  WHERE subject_to_class_certificate.subject_id = is_in_certificate.subject_id
                    AND subject_to_class_certificate.class_id = is_in_certificate.class_id);
end;
$$ language plpgsql;

CREATE FUNCTION get_theme_of_event(event_id integer)
    RETURNS integer
AS
$$
begin
    return (SELECT theme_id
            FROM events
            WHERE events.event_id = get_theme_of_event.event_id);
end;
$$ language plpgsql;

CREATE FUNCTION get_quarter_begin(quarter_id integer)
    RETURNS date
AS
$$
begin
    return (SELECT begin_date
            FROM quarters
            WHERE quarters.quarter_id = get_quarter_begin.quarter_id);
end;
$$ language plpgsql;

CREATE FUNCTION get_quarter_end(quarter_id integer)
    RETURNS date
AS
$$
begin
    return (SELECT end_date
            FROM quarters
            WHERE quarters.quarter_id = get_quarter_end.quarter_id);
end;
$$ language plpgsql;

CREATE FUNCTION get_quarter_year(quarter_id integer)
    RETURNS integer
AS
$$
begin
    if extract(month from get_quarter_end(quarter_id)) < 7 then
        return extract(year from get_quarter_end(quarter_id)) - 1;
    else
        return extract(year from get_quarter_end(quarter_id));
    end if;
end;
$$ language plpgsql;

CREATE FUNCTION get_quarter_order(quarter_id integer)
    RETURNS integer
AS
$$
begin
    return (SELECT COUNT(*)
            FROM quarters
            WHERE get_quarter_year(quarters.quarter_id) = get_quarter_year(get_quarter_order.quarter_id)
              AND quarters.begin_date < get_quarter_begin(get_quarter_order.quarter_id)) + 1;
end;
$$ language plpgsql;

CREATE FUNCTION get_now_quarter(at_date date)
    RETURNS integer
AS
$$
begin
    return (SELECT quarter_id
            FROM quarters
            WHERE quarters.begin_date <= at_date
              AND quarters.end_date <= at_date);
end;
$$ language plpgsql;

CREATE FUNCTION get_now_holiday(at_date date)
    RETURNS integer
AS
$$
begin
    return (SELECT holidays_id
            FROM holidays
            WHERE holidays.begin_date <= at_date
              AND holidays.end_date <= at_date);
end;
$$ language plpgsql;

CREATE FUNCTION get_quarter_of_theme(theme_id integer)
    RETURNS integer
AS
$$
begin
    return (SELECT quarter_id
            FROM themes
            WHERE themes.theme_id = get_quarter_of_theme.theme_id);
end;
$$ language plpgsql;

CREATE FUNCTION get_themes_in_quarter(subject_id1 integer, quarter_id1 integer)
    RETURNS table
            (
                theme_id integer
            )
AS
$$
begin
    return query SELECT theme_id
                 FROM themes
                 WHERE themes.subject_id = subject_id1
                   AND themes.quarter_id = quarter_id1;
end;
$$ language plpgsql;

CREATE FUNCTION get_mark_in_quarter(pupil_id integer, subject_id integer, quarter_id integer)
    RETURNS numeric(5, 3)
AS
$$
declare
    a numeric(5, 3);
    b numeric(5, 3);
    i integer;
begin
    if get_mandatory(subject_id) = False then
        raise exception 'Subject is not mandatory.';
    end if;
    for i in (SELECT get_themes_in_quarter(subject_id, quarter_id))
        loop
            a := a + get_mark_from_theme(pupil_id, i);
            b := b + 1;
        end loop;
    return a / b;
end;
$$ language plpgsql;

CREATE FUNCTION get_quarters_in_year(year integer)
    RETURNS table
            (
                quarter_id integer
            )
AS
$$
begin
    return query SELECT quarter_id
                 FROM quarters
                 WHERE get_quarter_year(quarter_id) = year;
end;
$$ language plpgsql;

CREATE FUNCTION get_mark_in_year(pupil_id integer, subject_id integer, year integer)
    RETURNS numeric(5, 3)
AS
$$
declare
    a numeric(5, 3);
    b numeric(5, 3);
    i integer;
begin
    if get_mandatory(subject_id) = False then
        raise exception 'Subject is not mandatory.';
    end if;
    for i in (SELECT get_quarters_in_year(year))
        loop
            a := a + get_mark_in_quarter(pupil_id, subject_id, i);
            b := b + 1;
        end loop;
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

ALTER TABLE schedule_history
    ADD CONSTRAINT schedule_history_if_mandatory_then_class_not_null
        CHECK (
                get_subject_of_schedule(schedule_history_id) IS NULL
                OR get_mandatory(get_subject_of_schedule(schedule_history_id)) = False
                OR
                (get_mandatory(get_subject_of_schedule(schedule_history_id)) = True
                    AND class_id IS NOT NULL));

ALTER TABLE schedule_history
    ADD CONSTRAINT schedule_history_mandatory_subjects_only_if_in_certificate
        CHECK (
                get_subject_of_schedule(schedule_history_id) IS NULL
                OR
                (get_mandatory(get_subject_of_schedule(schedule_history_id)) =
                 is_in_certificate(get_subject_of_schedule(schedule_history_id), class_id))
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

ALTER TABLE events
    ADD CONSTRAINT events_normal_event_date
        CHECK (
                get_now_quarter(event_date) IS NOT NULL
                AND get_now_holiday(event_date) IS NULL
            );

ALTER TABLE events
    ADD CONSTRAINT events_event_only_in_his_quarter
        CHECK (
                get_quarter_of_theme(get_theme_of_event(event_id)) = get_now_quarter(event_date)
            );

ALTER TABLE events
    ADD CONSTRAINT events_mandatory_subjects_only_if_in_certificate
        CHECK (
                get_subject_of_theme(get_theme_of_event(event_id)) IS NULL
                OR
                (get_mandatory(get_subject_of_theme(get_theme_of_event(event_id))) =
                 is_in_certificate(get_subject_of_theme(get_theme_of_event(event_id)), class_id))
            );

ALTER TABLE events
    ADD CONSTRAINT events_if_mandatory_then_class_not_null
        CHECK (
                get_subject_of_theme(get_theme_of_event(event_id)) IS NULL
                OR get_mandatory(get_subject_of_theme(get_theme_of_event(event_id))) = False
                OR
                (get_mandatory(get_subject_of_theme(get_theme_of_event(event_id))) = True
                    AND class_id IS NOT NULL));

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

ALTER TABLE quarters
    ADD CONSTRAINT quarters_quarter_in_one_semester
        CHECK (
                    extract(year from begin_date) = extract(year from end_date)
                AND extract(month from begin_date) != 7
                AND extract(month from end_date) != 7
                AND (extract(month from begin_date) < 7 AND extract(month from end_date) < 7
                OR extract(month from begin_date) > 7 AND extract(month from end_date) > 7)
            );

ALTER TABLE quarters
    ADD CONSTRAINT quarters_4_quarters_in_semester
        CHECK (
            get_quarter_order(quarter_id) <= 4
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
              FROM get_groups_of_pupil(NEW.pupil_id, NEW.change_time)
              WHERE get_group_class(group_id) IS NOT NULL
                AND get_group_class(group_id) != get_class(NEW.pupil_id, NEW.change_time))
        loop
            SELECT delete_from_group(NEW.pupil_id, i, NEW.change_time);
        end loop;
    return NEW;
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
                       FROM get_pupils_from_group(i, NOW()::timestamp) pupils
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
    BEFORE DELETE
    ON groups_to_events
    FOR EACH ROW
EXECUTE PROCEDURE groups_to_events_delete_trigger();

CREATE FUNCTION groups_to_schedule_same_subject_check_f(group_id integer, event_in_schedule_id integer)
    RETURNS boolean AS
$$
begin
    return ((SELECT subject_id
             FROM schedule_history
             WHERE schedule_history.schedule_history_id =
                   groups_to_schedule_same_subject_check_f.event_in_schedule_id) =
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
--data final block end


