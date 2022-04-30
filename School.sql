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
    date_of_birth date                   NOT NULL,
    "name"        varchar(100)           NOT NULL,
    surname       varchar(100)           NOT NULL,
    class_id      int REFERENCES classes NOT NULL,
    pupil_id      serial PRIMARY KEY
);

CREATE TABLE book_types
(
    subject_id         int REFERENCES subjects,
    name               varchar(100)         NOT NULL,
    author             varchar(100),
    "publication_year" numeric(4),
    "publication"      varchar(100),
    permission         numeric(1) DEFAULT 1 NOT NULL,
    type_id            serial PRIMARY KEY,

    CHECK (permission = 0 OR permission = 1)
);

CREATE TABLE books
(
    type_id   int REFERENCES book_types NOT NULL,
    condition numeric(2) DEFAULT 10     NOT NULL,
    book_id   serial PRIMARY KEY,

    CHECK (condition >= 0 AND condition <= 10)
);

CREATE TABLE books_history
(
    book_id         int REFERENCES books                      NOT NULL,
    event_time      timestamp without time zone DEFAULT now() NOT NULL,
    taken           boolean                     DEFAULT false NOT NULL,
    pupil_id        int REFERENCES pupils,
    teacher_id      int REFERENCES teachers,
    user_permission numeric(2)                  DEFAULT 0     NOT NULL,
    id              SERIAL PRIMARY KEY,

    CONSTRAINT user_id_checker
        CHECK ((user_permission = 0 AND pupil_id IS NOT NULL AND teacher_id IS NULL) OR
               (user_permission = 1 AND pupil_id IS NULL AND teacher_id IS NOT NULL))
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


