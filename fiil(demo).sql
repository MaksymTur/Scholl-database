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

insert into bell_schedule_history (bell_number, begin_time, end_time)
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

insert into excuses (pupil_id, reason, begin_bell, end_bell)
values (1, 'illness', ('2015-05-27', 1), ('2015-05-27', 6));
--  select * from excuses;

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

insert into pupil_groups (pupil_id, group_id)
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
--  select * from pupil_groups;

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

insert into workers_history (worker_id, post_id, from_time, to_time)
values (1, 3, '2021-08-09 07:00:00', default),
       (2, 1, '2021-08-09 07:01:00', default),
       (3, 2, '2021-08-09 07:02:00', '2021-08-15 07:02:00'),
       (3, 2, '2021-08-15 07:02:00', default),
       (3, 2, '2021-08-22 07:02:00', default),
       (2, 4, '2021-08-31 15:00:00', default),
       (3, 4, '2021-08-31 15:00:00', default);
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
values (2, 1, 10),
       (2, 2, 2),
       (3, 1, 4),
       (3, 2, 9),
       (4, 1, 5),
       (4, 2, 8),
       (5, 1, 7),
       (5, 3, 10),
       (6, 1, 9),
       (6, 3, 6),
       (7, 1, 10),
       (7, 3, 5);
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

insert into groups_to_events ("group", event)
values (1, 1),
       (2, 2),
       (3, 3);
-- select * from groups_to_events;

insert into groups_to_schedule ("group", event_in_schedule)
values (1, 1),
       (2, 4),
       (3, 5),
       (4, 3);
--  select * from groups_to_schedule;
