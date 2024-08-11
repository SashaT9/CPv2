create table users (
    user_id serial primary key,
    username text unique not null,
    password text,
    email text unique not null,
    role text not null
);
create table user_achievements (
    user_id int references users(user_id),
    problems_solve int,
    max_performance int,
    rating int,
    max_rating int,
    primary key (user_id)
);
create table user_settings_logs (
    user_id int references users(user_id),
    date_of_change timestamp default current_timestamp,
    description text,
    primary key (user_id, date_of_change)
);
create table topics (
    topic_id serial primary key,
    topic_name text unique not null -- for example number theory...
);
create table problems (
    problem_id serial primary key,
    statement text,
    answer text,
    output_only boolean default true,
    topic int references topics(topic_id)
);
create table solutions (
    solution_id serial primary key,
    answer text
);
create table submissions (
    user_id int references users(user_id),
    problem_id int references problems(problem_id),
    solution_id int references solutions(solution_id),
    status text,
    primary key (user_id, problem_id, solution_id)
);
create table tutorials (
    problem_id int references problems(problem_id),
    user_id int references users(user_id),
    tutorial text,
    primary key (problem_id, user_id)
);
create table contests (
    contest_id serial primary key,
    contest_name text not null,
    start_time timestamp,
    end_time timestamp,
    description text,
    is_active boolean default true
);

create table contest_problems (
    contest_id int references contests(contest_id),
    problem_id int references problems(problem_id),
    primary key (contest_id, problem_id)
);

create table contest_participants (
    contest_id int references contests(contest_id),
    user_id int references users(user_id),
    score int,
    rank int,
    primary key (contest_id, user_id)
);
create table announcements (
    announcement_id serial primary key,
    title text not null,
    content text,
    date_posted timestamp default current_timestamp
);
create table contest_announcements (
    contest_id int references contests(contest_id),
    announcement_id int references announcements(announcement_id),
    primary key (contest_id, announcement_id)
);
create table contest_feedback (
    contest_id int references contests(contest_id),
    user_id int references users(user_id),
    feedback text,
    rating int,
    date_submitted timestamp default current_timestamp,
    primary key (contest_id, user_id)
);