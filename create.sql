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