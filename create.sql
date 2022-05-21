DROP TABLE IF EXISTS schedule CASCADE;
DROP TABLE IF EXISTS book_types CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS books_history CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;
DROP TABLE IF EXISTS marks CASCADE;
DROP TABLE IF EXISTS "groups" CASCADE;
DROP TABLE IF EXISTS pupils CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS teachers CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS pupil_groups CASCADE;


CREATE TABLE rooms
(
    "name"  varchar(100) NOT NULL,
    seats   numeric(3)   NOT NULL,
    room_id serial PRIMARY KEY
);

CREATE TABLE classes
(
    "name"     varchar(100) NOT NULL,
    study_year numeric(2)   NOT NULL,
    class_id   serial PRIMARY KEY
);

CREATE TABLE teachers
(
    "name"     varchar(100) NOT NULL,
    surname    varchar(100) NOT NULL,
    teacher_id serial PRIMARY KEY
);

CREATE TABLE subjects
(
    "name"     varchar(100) NOT NULL,
    subject_id serial PRIMARY KEY
);

CREATE TABLE pupils
(
    date_of_birth date         NOT NULL,
    first_name    varchar(100) NOT NULL,
    second_name   varchar(100) NOT NULL,
    pupil_id      serial PRIMARY KEY
);

CREATE TABLE journal
(
    pupil_id int REFERENCES pupils NOT NULL,
    event_id int REFERENCES events NOT NULL
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

CREATE TABLE groups_history
(
    pupil_id    int REFERENCES pupils   NOT NULL,
    group_id    int REFERENCES "groups" NOT NULL,
    change_time timestamp DEFAULT now() NOT NULL,
    added       bool      DEFAULT TRUE  NOT NULL
);

CREATE TABLE "groups"
(
    class_id   int REFERENCES classes  NOT NULL,
    subject_id int REFERENCES subjects NOT NULL,
    group_id   serial PRIMARY KEY
);

CREATE TABLE pupil_groups
(
    pupil_id int REFERENCES pupils   NOT NULL,
    group_id int REFERENCES "groups" NOT NULL,
    id       serial PRIMARY KEY
);

CREATE TABLE lessons
(
    group_id   int REFERENCES "groups" NOT NULL,
    room_id    int REFERENCES rooms    NOT NULL,
    teacher_id int REFERENCES teachers NOT NULL,
    "number"   numeric(2)              NOT NULL,
    "date"     date DEFAULT now()      NOT NULL,
    lesson_id  serial PRIMARY KEY,

    UNIQUE (room_id, "number", date)
);

CREATE TABLE marks
(
    pupil_id  int REFERENCES pupils  NOT NULL,
    lesson_id int REFERENCES lessons NOT NULL,
    mark      numeric(2)             NOT NULL,
    id        serial PRIMARY KEY,

    UNIQUE (pupil_id, lesson_id)
);

CREATE TYPE bell_event AS
(
    "day" date,
    bell  integer
);


