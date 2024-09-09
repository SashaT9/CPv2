create table users (
    user_id serial primary key,
    username text unique not null,
    password text not null,
    email text unique not null,
    role text not null
);
create table user_achievements (
    user_id int references users(user_id) on delete cascade,
    problems_solve int not null default 0,
    max_performance int not null default 0,
    rating int not null default 0,
    max_rating int not null default 0,
    primary key (user_id)
);
create table topics (
    topic_id serial primary key,
    topic_name text unique not null -- for example number theory...
);
create table problems (
    problem_id serial primary key,
    statement text not null,
    answer text not null,
    output_only boolean default true
);

create table problems_topics (
    problem_id int references problems(problem_id) on delete cascade,
    topic int references topics(topic_id),
    primary key (problem_id, topic)
);

create table solutions (
    solution_id serial primary key,
    answer text not null
);
create table submissions (
    user_id int references users(user_id) on delete cascade,
    problem_id int references problems(problem_id) on delete cascade,
    solution_id int references solutions(solution_id) on delete cascade,
    date_of_submission timestamp default current_timestamp,
    status text,
    primary key (user_id, problem_id, solution_id)
);
create table tutorials (
    problem_id int references problems(problem_id) on delete cascade,
    user_id int references users(user_id) on delete cascade,
    tutorial text not null,
    primary key (problem_id, user_id)
);
create table contests (
    contest_id serial primary key,
    contest_name text not null,
    start_time timestamp not null,
    end_time timestamp not null check(end_time>start_time),
    description text not null
);

create table contest_problems (
    contest_id int references contests(contest_id) on delete cascade,
    problem_id int references problems(problem_id) on delete cascade,
    primary key (contest_id, problem_id)
);

create table contest_participants (
    contest_id int references contests(contest_id) on delete cascade,
    user_id int references users(user_id) on delete cascade,
    score int not null default 0,
    primary key (contest_id, user_id)
);

create table announcements (
    announcement_id serial primary key,
    title text not null,
    content text not null,
    date_posted timestamp not null default current_timestamp
);
create table contest_announcements (
    contest_id int references contests(contest_id) on delete cascade,
    announcement_id int references announcements(announcement_id) on delete cascade,
    primary key (contest_id, announcement_id)
);
create table contest_feedback (
    contest_id int references contests(contest_id) on delete cascade,
    user_id int references users(user_id) on delete cascade,
    feedback text not null,
    rating int not null,
    date_submitted timestamp not null default current_timestamp,
    primary key (contest_id, user_id)
);

create table user_history (
    user_history_id serial primary key,
    user_id int references users(user_id) on delete cascade,
    date_of_change timestamp default current_timestamp,
    description text not null
);

create table problem_history (
    problem_history_id serial primary key,
    problem_id int references problems(problem_id) on delete cascade,
    date_of_change timestamp default current_timestamp,
    description text not null
);

create table announcement_history (
    announcement_history_id serial primary key,
    announcement_id int references announcements(announcement_id) on delete cascade,
    date_of_change timestamp default current_timestamp,
    description text not null
);

create table contest_history (
    contest_history_id serial primary key,
    contest_id int references contests(contest_id) on delete cascade,
    date_of_change timestamp default current_timestamp,
    description text not null
);

create index idx_user_achievements_user_id on user_achievements(user_id);
create index idx_user_achievements_user_id_rating on user_achievements(user_id, rating);
create index idx_submissions_user_problem_status on submissions(user_id, problem_id, status);
create index idx_submissions_problem_id on submissions(problem_id);
create index idx_contest_participants_contest_user on contest_participants(contest_id, user_id);
create index idx_contests_contest_id on contests(contest_id);
create index idx_contests_end_time on contests(end_time);
create index idx_contest_problems_contest_problem on contest_problems(contest_id, problem_id);
create index idx_problems_problem_id on problems(problem_id);
create index idx_users_user_id on users(user_id);
