CREATE TYPE week_day AS enum('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');
CREATE TYPE parity AS enum('odd', 'even');
CREATE TYPE bell_event AS
(
    "day" date,
    bell  integer
);

CREATE TABLE rooms
(
    title     text    NOT NULL,
    room_type text    NOT NULL,
    seats     integer NOT NULL,
    room_id   serial PRIMARY KEY

);

/*CREATE TABLE classes
(
    "name"     varchar(100) NOT NULL,
    study_year numeric(2)   NOT NULL,
    class_id   serial PRIMARY KEY
);*/

CREATE TABLE subjects
(
    title      text NOT NULL,
    subject_id serial PRIMARY KEY
);

CREATE TABLE pupils
(
    date_of_birth date         NOT NULL,
    first_name    varchar(100) NOT NULL,
    second_name   varchar(100) NOT NULL,
    pupil_id      serial PRIMARY KEY
);

CREATE TABLE themes
(
    title text NOT NULL,
    lessons_length integer NOT NULL,
    theme_order integer NOT NULL,

    theme_id serial PRIMARY KEY
);

CREATE TABLE excuses
(
    pupil_id   int REFERENCES pupils NOT NULL,
    reason     text,
    begin_bell bell_event,
    end_bell   bell_event
);

CREATE TABLE bell_shedule_history
(
    bell_number int,
    begin_time  time                    NOT NULL,
    end_time    time                    NOT NULL,
    change_time timestamp DEFAULT now() NOT NULL
);

CREATE TABLE "groups"
(
    subject_id integer REFERENCES subjects NOT NULL,
    group_id   serial PRIMARY KEY
);

CREATE TABLE groups_history
(
    pupil_id    int REFERENCES pupils   NOT NULL,
    group_id    int REFERENCES "groups" NOT NULL,
    add_time timestamp DEFAULT now() NOT NULL,
    deletion_time timestamp DEFAULT NULL
);

CREATE TABLE pupil_groups
(
    pupil_id int REFERENCES pupils   NOT NULL,
    group_id int REFERENCES "groups" NOT NULL,
    id       serial PRIMARY KEY
);

CREATE TABLE workers(
    first_name text,
    second_name text,
    worker_id serial PRIMARY KEY
);

CREATE TABLE posts(
    title text,
    post_id serial PRIMARY KEY
);

CREATE TABLE workers_history(
    worker_id int REFERENCES workers NOT NULL,
    post_id int REFERENCES posts NOT NULL,
    added boolean NOT NULL,
    change_time timestamp NOT NULL,

    PRIMARY KEY (worker_id, post_id, change_time)
);

CREATE TABLE schedule_history
(
    teacher_id integer REFERENCES workers,
    room_id integer REFERENCES rooms,
    bell_number integer,
    "week_day" week_day NOT NULL,
    week_pair parity,
    change_time timestamp DEFAULT now() NOT NULL,

    id serial PRIMARY KEY,

    UNIQUE (room_id, bell_number, "week_day", week_pair)
);

CREATE TABLE events
(
    room_id          integer REFERENCES rooms,
    teacher_id       integer REFERENCES workers       NOT NULL,
    theme_id         integer REFERENCES themes,
    event_time       bell_event                        NOT NULL,
    event_id         serial PRIMARY KEY,

    UNIQUE (room_id, event_time)
);

CREATE TABLE marks
(
    pupil_id integer REFERENCES pupils NOT NULL,
    event_id integer REFERENCES events NOT NULL,
    mark     integer                   NOT NULL,

    PRIMARY KEY (pupil_id, event_id)
);

CREATE TABLE quarters
(
    begin_date date NOT NULL,
    end_date date NOT NULL
);

CREATE TABLE holidays
(
    begin_date date NOT NULL,
    end_date date NOT NULL
);

CREATE TABLE salary_history(
    worker_id int REFERENCES workers NOT NULL,
    salary int NOT NULL,
    change_time timestamp NOT NULL,

    PRIMARY KEY (worker_id, change_time)
);

CREATE TABLE classes(
    title text NOT NULL,
    study_year int NOT NULL,
    class_id serial PRIMARY KEY,

    CHECK (study_year > 0 AND study_year < 13)
);

CREATE TABLE class_history(
    pupil_id int REFERENCES pupils NOT NULL,
    class_id int REFERENCES  classes NOT NULL,
    add_time timestamp NOT NULL,
    deletion_time timestamp DEFAULT NULL,

    PRIMARY KEY (pupil_id, class_id, add_time)
);

CREATE TABLE class_teacher_history(
    class_id int REFERENCES classes NOT NULL,
    teacher_id int REFERENCES workers NOT NULL,
    change_time timestamp NOT NULL,
    PRIMARY KEY (class_id, teacher_id, change_time)
);

CREATE TABLE journal
(
    pupil_id int REFERENCES pupils NOT NULL,
    event_id int REFERENCES events NOT NULL
);

CREATE TABLE groups_to_events(
    "group" int REFERENCES groups NOT NULL,
    event int REFERENCES events NOT NULL
);

CREATE TABLE groups_to_schedule(
    "group" int REFERENCES groups NOT NULL,
    event_in_schedule int REFERENCES schedule_history NOT NULL
);

insert into rooms (title, room_type, seats)
values ('101a', 'gym', 40), ('102a', 'basic', 8), ('102b', 'basic', 8), ('102c', 'basic', 8);
-- select * from rooms;

insert into subjects (title)
values ('Mathematics'), ('English');
--  select * from subjects;

insert into pupils (date_of_birth, first_name, second_name)
values
    ('2015-01-23', 'Ernie', 'Webber'),
    ('2015-02-15', 'Ismail', 'Ferrell'),
    ('2015-04-25', 'Salahuddin', 'Fellows'),
    ('2015-05-04', 'Corban', 'Hirst'),
    ('2015-05-10', 'Fraya', 'Greene'),
    ('2015-05-15', 'Ida', 'Robins'),
    ('2015-05-21', 'Timur', 'Blackwell'),
    ('2015-07-23', 'Ellise', 'Knox');
-- select * from pupils;

insert into themes (title, lessons_length, theme_order)
values ('Addition', 20, 1), ('Subtraction', 20, 2), ('Alphabet', 10, 1), ('Words', 30, 2);
-- select * from themes;

insert into bell_shedule_history (bell_number, begin_time, end_time)
values
(1, '08:00', '08:45'), (2, '09:00', '09:45'), (3, '09:55', '10:40'), (4, '10:55', '11:40'), (5, '12:00', '12:45'), (6, '13:05', '13:50');
--  select * from bell_shedule_history;

insert into groups (subject_id)
values (1), (2), (2), (2);
--  select * from groups;

insert into excuses (pupil_id, reason, begin_bell, end_bell)
values (1, 'illness', ('2015-05-27', 1), ('2015-05-27', 6));
--  select * from excuses;

insert into groups_history (pupil_id, group_id)
values (1, 1), (1, 2),
       (2, 1), (2, 2),
       (3, 1), (3, 2),
       (4, 1), (4, 2),
       (5, 1), (5, 3),
       (6, 1), (6, 3),
       (7, 1), (7, 3),
       (8, 4);
--  select * from groups_history;

insert into pupil_groups (pupil_id, group_id)
values (1, 1), (1, 2),
       (2, 1), (2, 2),
       (3, 1), (3, 2),
       (4, 1), (4, 2),
       (5, 1), (5, 3),
       (6, 1), (6, 3),
       (7, 1), (7, 3),
       (8, 4);
--  select * from pupil_groups;

insert into workers (first_name, second_name)
values ('Maksym', 'Tur'), ('Andrii', 'Kovryhin'), ('Aliaksandr', 'Skvarniuk');
--  select * from workers;

insert into posts (title)
values ('Director'), ('Head teacher'), ('Accountant'), ('classroom teacher');
--  select * from posts;

insert into workers_history (worker_id, post_id, added, change_time)
values (1, 3, true, '2021-08-09 07:00:00'),
       (2, 1, true, '2021-08-09 07:01:00'),
       (3, 2, true, '2021-08-09 07:02:00'),
       (3, 2, false, '2021-08-15 07:02:00'),
       (3, 2, true, '2021-08-22 07:02:00'),
       (2, 4, true, '2021-08-31 15:00:00'),
       (3, 4, true, '2021-08-31 15:00:00');
--  select * from workers_history;

insert into schedule_history (teacher_id, room_id, bell_number, week_day, week_pair)
values (2, 2, 1, 'Thursday', 'odd'),
       (2, 2, 1, 'Thursday', 'even'),
       (1, 4, 1, 'Thursday', 'even'),
       (3, 2, 2, 'Thursday', 'odd'),
       (2, 3, 2, 'Thursday', 'odd');
--  select * from schedule_history;

insert into events (room_id, teacher_id, theme_id, event_time)
values (3, 2, 1, ('2015-05-27', 1)),
       (2, 3, 3, ('2015-05-27', 2)),
       (3, 1, 3, ('2015-05-27', 2));
--  select * from events;

insert into marks (pupil_id, event_id, mark)
values (2, 1, 10), (2, 2, 2),
       (3, 1, 4), (3, 2, 9),
       (4, 1, 5), (4, 2, 8),
       (5, 1, 7), (5, 3, 10),
       (6, 1, 9), (6, 3, 6),
       (7, 1, 10), (7, 3, 5);
    --    select * from marks;

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
values ('A', 1), ('B', 1);
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

insert into journal (pupil_id, event_id)
values (2, 1), (2, 2),
       (3, 1), (3, 2),
       (4, 1), (4, 2),
       (5, 1), (5, 3),
       (6, 1), (6, 3),
       (7, 1), (7, 3);
-- select * from journal;

insert into groups_to_events ("group", event)
values (1, 1), (2, 2), (3, 3);
-- select * from groups_to_events;

insert into groups_to_schedule ("group", event_in_schedule)
values (1, 1), (2, 4), (3, 5), (4, 3);
--  select * from groups_to_schedule;





