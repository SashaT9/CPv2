drop table users cascade;
drop table user_achievements cascade ;
drop table topics cascade ;
drop table problems cascade ;
drop table problems_topics cascade;
drop table solutions cascade ;
drop table submissions cascade ;
drop table tutorials cascade ;
drop table contests cascade ;
drop table contest_problems cascade ;
drop table contest_participants cascade ;
drop table announcements cascade ;
drop table contest_announcements cascade ;
drop table contest_feedback cascade ;
drop table user_history cascade ;
drop table problem_history cascade ;
drop table announcement_history cascade ;
drop table contest_history cascade ;

drop function if exists insert_default_achievements(integer);
drop function if exists upd_user_achievements_after_retest(integer,integer);
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
create index idx_problems_of_topics on problems_topics(problem_id);
create index idx_topics_of_problems on problems_topics(topic);

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
    description text not null,
    is_active boolean not null default true
);

create table contest_problems (
    contest_id int references contests(contest_id) on delete cascade,
    problem_id int references problems(problem_id) on delete cascade,
    primary key (contest_id, problem_id)
);
create index idx_problems_in_contest on contest_problems(contest_id);

create table contest_participants (
    contest_id int references contests(contest_id) on delete cascade,
    user_id int references users(user_id) on delete cascade,
    score int not null default 0,
    rank int,
    primary key (contest_id, user_id)
);
create index on contest_participants(user_id);
create index on contest_participants(contest_id);
create index on contest_participants(rank);

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
create or replace function insert_default_achievements(muser_id int)
returns void as $$
begin
    if not exists(
        select * from user_achievements where user_id = muser_id
    ) then
        insert into user_achievements(user_id, problems_solve, max_performance, rating, max_rating)
        values (muser_id, 0, 0, 0, 0);
    end if;
end;
$$ language plpgsql;

create or replace function upd_user_achievements_after_retest(mproblem_id int, delta int)
returns void as $$
begin
    update user_achievements
    set problems_solve = problems_solve + delta
    where user_id in (
        select distinct user_id
        from submissions
        where problem_id = mproblem_id and status = 'accepted'
    );
    update contest_participants
    set score = score + delta
    where user_id in (
        select distinct user_id
        from submissions
        where problem_id = mproblem_id
        and status = 'accepted'
        and date_of_submission <= (
            select end_time
            from contests
            where contests.contest_id = contest_participants.contest_id
        )
    );
end;
$$ language plpgsql;
-- CREATE OR REPLACE FUNCTION log_user_settings_changes()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     -- Username change
--     IF (NEW.username IS DISTINCT FROM OLD.username) THEN
--         INSERT INTO user_settings_logs(user_id, date_of_change, description)
--         VALUES (OLD.user_id, CURRENT_TIMESTAMP, 'Username changed from ' || OLD.username || ' to ' || NEW.username);
--     END IF;
--
--     -- Password change
--     IF (NEW.password IS DISTINCT FROM OLD.password) THEN
--         INSERT INTO user_settings_logs(user_id, date_of_change, description)
--         VALUES (OLD.user_id, CURRENT_TIMESTAMP, 'Password changed');
--     END IF;
--
--     -- Email change
--     IF (NEW.email IS DISTINCT FROM OLD.email) THEN
--         INSERT INTO user_settings_logs(user_id, date_of_change, description)
--         VALUES (OLD.user_id, CURRENT_TIMESTAMP, 'Email changed from ' || OLD.email || ' to ' || NEW.email);
--     END IF;
--
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
-- CREATE OR REPLACE TRIGGER user_settings_trigger
-- AFTER UPDATE ON users
-- FOR EACH ROW
-- EXECUTE FUNCTION log_user_settings_changes();

create or replace function valid_email()
returns trigger as $$
begin
    if(not (new.email ~ '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$')) then
        raise exception 'Invalid email address: %', new.email;
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger valid_email_trigger
before insert or update on users
for each row
execute function valid_email();

create or replace function valid_username()
returns trigger as $$
begin
    if((new.username ~ ' ')) then
        raise exception 'Username cannot contain spaces %', new.username;
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger valid_username_trigger
before insert or update on users
for each row
execute function valid_username();

--trigger for updating achievements after each submission
create or replace function update_achievements()
returns trigger as $$
begin
    perform insert_default_achievements(new.user_id);
    if (new.status = 'accepted') then
        if (
            select count(*) from submissions
            where user_id = new.user_id and problem_id = new.problem_id and status = 'accepted'
        ) = 1
        then
            update user_achievements
            set problems_solve = problems_solve + 1
            where user_id = new.user_id;
        end if;
    end if;
    return new;
end;
$$ language plpgsql;
create trigger after_problem_solved
after insert on submissions
for each row
execute function update_achievements();

--trigger for retest problem submissions after updating the problem's answer. (it also changes user achievements)
create or replace function retest_problem_solutions()
returns trigger as $$
begin
    if (old.answer = new.answer) then
        return new;
    end if;
    perform upd_user_achievements_after_retest(old.problem_id, -1);
    update submissions set status =
    (case when solutions.answer = new.answer then 'accepted' else 'wrong answer' end)
    from solutions where submissions.solution_id = solutions.solution_id and submissions.problem_id = new.problem_id;
    perform upd_user_achievements_after_retest(new.problem_id, 1);
    return new;
end;
$$ language plpgsql;
create or replace trigger retest_problem_trigger
after update on problems
for each row
execute function retest_problem_solutions();

-----------------------------------------------------------
create or replace function default_achievements_from_start()
returns trigger as $$
begin
    perform insert_default_achievements(new.user_id);
    return new;
end;
$$ language plpgsql;
create or replace trigger default_achievements_trigger
after insert on users
for each row
execute function default_achievements_from_start();

----------------------------------------------------------
create or replace function update_ranking()
returns trigger as $$
declare
    submission_count int;
begin
    if (new.status = 'wrong answer') then
        return new;
    end if;

    select count(*) into submission_count
    from submissions
    where user_id = new.user_id and problem_id = new.problem_id and status = 'accepted';

    if submission_count = 1 then
        update contest_participants
        set score = score + 1
        where contest_participants.user_id = new.user_id
        and contest_participants.contest_id in (
            select contests.contest_id
            from contests
            where new.date_of_submission <= contests.end_time
        )
        and new.problem_id in (
            select contest_problems.problem_id
            from contest_problems
            where contest_problems.contest_id = contest_participants.contest_id
        );
    end if;

    return new;
end;
$$ language plpgsql;
create or replace trigger update_ranking_trigger
after insert on submissions
for each row
execute function update_ranking();

---------------------------------------------------
create or replace function default_score_for_contest()
returns trigger as $$
declare
    solved_problems_count int;
begin
    select count(distinct problem_id) into solved_problems_count
    from submissions
    where user_id = new.user_id and status = 'accepted';

    update contest_participants
    set score = solved_problems_count
    where contest_participants.user_id = new.user_id
    and contest_participants.contest_id = new.contest_id;

    return new;
end;
$$ language plpgsql;
create trigger update_score_after_insert
after insert on contest_participants
for each row
execute function default_score_for_contest();

--------------------------------------------------------------
create or replace function update_score_on_new_problem()
returns trigger as $$
begin
    update contest_participants
    set score = score + 1
    where contest_id = new.contest_id
    and user_id in (
        select distinct user_id
        from submissions
        where problem_id = new.problem_id
        and status = 'accepted'
    );
    return new;
end;
$$ language plpgsql;
create trigger update_score_on_problem_insert
after insert on contest_problems
for each row
execute function update_score_on_new_problem();

-------------------------------------------------------------
create or replace function update_score_on_delete_problem()
returns trigger as $$
begin
    update contest_participants
    set score = score - 1
    where contest_id = old.contest_id
    and user_id in (
        select distinct user_id
        from submissions
        where problem_id = old.problem_id
        and status = 'accepted'
    );
    return old;
end;
$$ language plpgsql;
create trigger update_score_on_delete_problem
after delete on contest_problems
for each row
execute function update_score_on_delete_problem();

insert into users(username, password, email, role) values
('BraveLeopard248', 'bp17ltfa3w1', 'BraveLeopard248@smile.sad', 'user'),
('SwiftBear538', '2ufp850akr02', 'SwiftBear538@cpv2.com', 'user'),
('BrightEagle543', '8485ew575362', 'BrightEagle543@cpv2.com', 'user'),
('HappyOtter635', 'o08ohln5', 'HappyOtter635@gmail.com', 'user'),
('QuietTiger728', 'b105m4', 'QuietTiger728@smile.sad', 'user'),
('MightyHawk530', '64lxvdky77vu', 'MightyHawk530@akame.eris', 'user'),
('WildLion357', '5n5690', 'WildLion357@gmail.com', 'user'),
('BrightHawk811', 'c60m83a', 'BrightHawk811@smile.sad', 'user'),
('WildLion761', 'u62o7xb38', 'WildLion761@akame.eris', 'user'),
('SlyPanther841', 'mt9fe8dda57', 'SlyPanther841@gmail.com', 'user'),
('LazyRaven828', 'v58a1hj79f07', 'LazyRaven828@akame.eris', 'user'),
('LoyalRaven758', '0ebt0x5m', 'LoyalRaven758@cpv2.com', 'user'),
('MightyBear78', '8qe50wh880', 'MightyBear78@smile.sad', 'user'),
('HappyEagle787', '5obk5my', 'HappyEagle787@smile.sad', 'user'),
('BoldShark479', '97d4o0pam3b', 'BoldShark479@smile.sad', 'user'),
('BraveViper906', 't7q210', 'BraveViper906@smile.sad', 'user'),
('BoldPanther907', 'uswmp8e60', 'BoldPanther907@gmail.com', 'user'),
('LoyalBadger919', '0843u168', 'LoyalBadger919@cpv2.com', 'user'),
('SwiftWolf926', 'n0i8y56', 'SwiftWolf926@cpv2.com', 'user'),
('GentleDragon643', '5x892q', 'GentleDragon643@cpv2.com', 'user'),
('SwiftJaguar189', '5qf89l', 'SwiftJaguar189@cpv2.com', 'user'),
('BrightLion307', 'v6j4dy58vxw', 'BrightLion307@cpv2.com', 'user'),
('GentleOtter851', '4o99z95fc0', 'GentleOtter851@cpv2.com', 'user'),
('MightyCobra907', '2l6z48', 'MightyCobra907@gmail.com', 'user'),
('LoyalFox824', '8m17s84596b3', 'LoyalFox824@smile.sad', 'user'),
('SadHawk820', '1j8ks6n47', 'SadHawk820@smile.sad', 'user'),
('QuietLion636', '2l0x07', 'QuietLion636@akame.eris', 'user'),
('DarkCheetah446', '3nc98w4q54', 'DarkCheetah446@cpv2.com', 'user'),
('GentleDragon545', '6p498g2h0r', 'GentleDragon545@akame.eris', 'user'),
('ShyHawk624', '13zccw1ta', 'ShyHawk624@cpv2.com', 'user'),
('SadFalcon491', '4f938p56gb', 'SadFalcon491@gmail.com', 'user'),
('BraveViper290', 'h7u197mny', 'BraveViper290@cpv2.com', 'user'),
('LazyTiger429', '2j5cv9v', 'LazyTiger429@smile.sad', 'user'),
('LazyViper483', '03r160x92kvq', 'LazyViper483@akame.eris', 'user'),
('BoldCobra598', 'rjukjk4q38j', 'BoldCobra598@smile.sad', 'user'),
('DarkFalcon198', 'jno929i3', 'DarkFalcon198@smile.sad', 'user'),
('CalmViper154', '65mce5ngltg2', 'CalmViper154@gmail.com', 'user'),
('DarkWolf125', '6l27asy5h01', 'DarkWolf125@cpv2.com', 'user'),
('LazyCheetah854', 'x7h5vk4n', 'LazyCheetah854@smile.sad', 'user'),
('CleverCheetah277', 'u46579k', 'CleverCheetah277@smile.sad', 'user'),
('BoldDragon745', '42t4dkbv4', 'BoldDragon745@akame.eris', 'user'),
('FierceDragon481', '67850h9', 'FierceDragon481@smile.sad', 'user'),
('MightyCobra956', 'ubw008jfh', 'MightyCobra956@akame.eris', 'user'),
('StrongFox490', 'jpmmtq437y', 'StrongFox490@akame.eris', 'user'),
('StrongPanther732', '1a437rdgy', 'StrongPanther732@akame.eris', 'user'),
('WildTiger770', '6ccocy3o', 'WildTiger770@cpv2.com', 'user'),
('StrongPanther659', '4z7wl26535', 'StrongPanther659@gmail.com', 'user'),
('FierceShark555', '3cz449c3', 'FierceShark555@gmail.com', 'user'),
('HappyCobra29', '92429epauj', 'HappyCobra29@gmail.com', 'user'),
('MightyJaguar480', '2luzzzj8u', 'MightyJaguar480@cpv2.com', 'user'),
('SadLion115', '04925f167pp', 'SadLion115@gmail.com', 'user'),
('BraveBear691', '4766ox3', 'BraveBear691@smile.sad', 'user'),
('BrightBadger383', '19ht58', 'BrightBadger383@smile.sad', 'user'),
('HappyViper679', '0bf2m3ht5c71', 'HappyViper679@gmail.com', 'user'),
('BravePanda442', 'mv9d6y', 'BravePanda442@cpv2.com', 'user'),
('CleverCobra164', '755q8ne38', 'CleverCobra164@cpv2.com', 'user'),
('StrongRaven249', '5dl1913a98f', 'StrongRaven249@akame.eris', 'user'),
('SlyOtter752', 'uolc1d0qqwp', 'SlyOtter752@cpv2.com', 'user'),
('CalmWolf537', 'rb92rg1uqhn3', 'CalmWolf537@smile.sad', 'user'),
('ShyPanda79', 'lvou93s1u3eq', 'ShyPanda79@gmail.com', 'user'),
('GentlePanther8', 'dm3c3n06hiy', 'GentlePanther8@cpv2.com', 'user'),
('LoyalDragon240', '85jc044', 'LoyalDragon240@smile.sad', 'user'),
('QuickEagle729', '666g74', 'QuickEagle729@gmail.com', 'user'),
('FierceBadger287', 'j39q8x1v4qr', 'FierceBadger287@akame.eris', 'user'),
('QuietBadger745', 'zm1bl7d', 'QuietBadger745@akame.eris', 'user'),
('StrongFalcon859', '83l0i4m', 'StrongFalcon859@smile.sad', 'user'),
('DarkCheetah953', '1n3qo5x', 'DarkCheetah953@akame.eris', 'user'),
('MightyViper812', '4x6mp1ahe', 'MightyViper812@akame.eris', 'user'),
('SwiftLeopard519', '35c8z8ftid', 'SwiftLeopard519@smile.sad', 'user'),
('FiercePanther478', 'f32dw8e46', 'FiercePanther478@cpv2.com', 'user'),
('CleverCobra81', 'd5l3o7y', 'CleverCobra81@akame.eris', 'user'),
('StrongShark190', '1l4i61j8c', 'StrongShark190@gmail.com', 'user'),
('BoldBear464', '59bbsn', 'BoldBear464@cpv2.com', 'user'),
('LazyCheetah48', 'bh965093', 'LazyCheetah48@cpv2.com', 'user'),
('BraveBear548', '73p63hbq', 'BraveBear548@smile.sad', 'user'),
('MightyPanther847', '2xb5w2zd036u', 'MightyPanther847@akame.eris', 'user'),
('SwiftPanda904', '2n4li1q5yw3u', 'SwiftPanda904@gmail.com', 'user'),
('GentleFalcon710', 'u2sssh5wg8o3', 'GentleFalcon710@gmail.com', 'user'),
('SwiftBear931', '0g5r08x', 'SwiftBear931@smile.sad', 'user'),
('CalmViper286', '1z55747p', 'CalmViper286@cpv2.com', 'user'),
('ShyWolf804', 'o43sj31jkp0f', 'ShyWolf804@gmail.com', 'user'),
('FierceBadger392', 's0t2rv14', 'FierceBadger392@gmail.com', 'user'),
('MightyPanther770', '4447k95q99', 'MightyPanther770@smile.sad', 'user'),
('MightyCheetah212', '4ci06fqc59', 'MightyCheetah212@gmail.com', 'user'),
('DarkRaven528', '2csog497', 'DarkRaven528@akame.eris', 'user'),
('MightyWolf853', '0d9501rrnq2v', 'MightyWolf853@smile.sad', 'user'),
('LazyCheetah583', '5fw73327', 'LazyCheetah583@akame.eris', 'user'),
('BraveShark681', '6r86w0cs', 'BraveShark681@gmail.com', 'user'),
('LoyalPanther67', 'nx65z6', 'LoyalPanther67@smile.sad', 'user'),
('MightyViper610', 'o81304d', 'MightyViper610@gmail.com', 'user'),
('StrongPanther221', '360x872gwo', 'StrongPanther221@smile.sad', 'user'),
('GentlePanda994', 'ko8e24t0g', 'GentlePanda994@akame.eris', 'user'),
('SwiftHawk9', 'u6y0260', 'SwiftHawk9@cpv2.com', 'user'),
('FierceTiger915', 'z5362u', 'FierceTiger915@smile.sad', 'user'),
('HappyTiger96', '0m239966u8y2', 'HappyTiger96@cpv2.com', 'user'),
('SlyFox355', '1kh836d3ny', 'SlyFox355@gmail.com', 'user'),
('HappyOtter968', 'zsq488w630', 'HappyOtter968@smile.sad', 'user'),
('CalmBadger798', 'u98ttk5vu4', 'CalmBadger798@akame.eris', 'user'),
('GentleLion726', 'qe32z6y', 'GentleLion726@gmail.com', 'user'),
('WildLion652', 'c8hhd3h7r03', 'WildLion652@cpv2.com', 'user'),
('GentleViper819', '8cdk8z5', 'GentleViper819@smile.sad', 'user'),
('SwiftViper668', 'znx2j5x2', 'SwiftViper668@cpv2.com', 'user'),
('LazyCheetah533', '1l3l77c1y', 'LazyCheetah533@gmail.com', 'user'),
('SlyWolf794', 'y59g5899', 'SlyWolf794@akame.eris', 'user'),
('StrongLeopard320', '56o7qb', 'StrongLeopard320@gmail.com', 'user'),
('StrongRaven794', '8aw45c168', 'StrongRaven794@akame.eris', 'user'),
('WildCobra797', '5b2646', 'WildCobra797@akame.eris', 'user'),
('FierceLeopard116', 'kur978frd3', 'FierceLeopard116@smile.sad', 'user'),
('QuietEagle247', 'zth46vp4p', 'QuietEagle247@cpv2.com', 'user'),
('HappyHawk700', 'l1c9drw7', 'HappyHawk700@smile.sad', 'user'),
('BrightFalcon651', '2h57aej4od1', 'BrightFalcon651@akame.eris', 'user'),
('GentleJaguar723', '32qcs426zanq', 'GentleJaguar723@smile.sad', 'user'),
('QuickShark188', '1317d7', 'QuickShark188@akame.eris', 'user'),
('DarkShark798', 'l9e6uk7zj3', 'DarkShark798@cpv2.com', 'user'),
('GentleLeopard496', 'w2a7vg936x', 'GentleLeopard496@gmail.com', 'user'),
('SlyTiger458', '8wea0q3s4m72', 'SlyTiger458@akame.eris', 'user'),
('SadTiger333', '3e78r9g', 'SadTiger333@gmail.com', 'user'),
('BraveCheetah416', 'rfke74r6w', 'BraveCheetah416@smile.sad', 'user'),
('LoyalJaguar727', 's7qqbop', 'LoyalJaguar727@akame.eris', 'user'),
('DarkBadger918', '6e91q7', 'DarkBadger918@smile.sad', 'user'),
('CalmBadger2', 'l23v8751rt', 'CalmBadger2@gmail.com', 'user'),
('GentleHawk613', 'p31y48ktl7g9', 'GentleHawk613@cpv2.com', 'user'),
('SwiftShark651', '2ge50h84p', 'SwiftShark651@gmail.com', 'user'),
('CalmJaguar472', 'r5yh42', 'CalmJaguar472@akame.eris', 'user'),
('FierceHawk375', '2ik4f45e8', 'FierceHawk375@akame.eris', 'user'),
('StrongLeopard592', '88pu58c8z', 'StrongLeopard592@smile.sad', 'user'),
('StrongJaguar51', 'n0764qdu', 'StrongJaguar51@cpv2.com', 'user'),
('BrightDragon367', 'svt3g91', 'BrightDragon367@cpv2.com', 'user'),
('FierceViper741', '042xl4n', 'FierceViper741@gmail.com', 'user'),
('SlyPanda13', 't69z688', 'SlyPanda13@cpv2.com', 'user'),
('DarkPanther87', 'jt7sq71f6', 'DarkPanther87@smile.sad', 'user'),
('DarkRaven158', '57wl7nholy6u', 'DarkRaven158@smile.sad', 'user'),
('SadLion151', 'pm8s3qlcv2v', 'SadLion151@cpv2.com', 'user'),
('CleverFox529', '10o3ev64f2', 'CleverFox529@smile.sad', 'user'),
('CleverEagle479', '0474rw6', 'CleverEagle479@akame.eris', 'user'),
('BrightHawk67', 'pn5syx', 'BrightHawk67@cpv2.com', 'user'),
('HappyJaguar982', 'sghycd6', 'HappyJaguar982@smile.sad', 'user'),
('LazyTiger365', '2826o96l', 'LazyTiger365@gmail.com', 'user'),
('LoyalHawk302', '1lvdu1', 'LoyalHawk302@smile.sad', 'user'),
('SwiftJaguar979', 'fuee3vu', 'SwiftJaguar979@smile.sad', 'user'),
('QuietTiger84', '92obl5o', 'QuietTiger84@smile.sad', 'user'),
('SwiftShark932', '84lgn5s5r', 'SwiftShark932@smile.sad', 'user'),
('LoyalEagle362', '61pd013f5', 'LoyalEagle362@smile.sad', 'user'),
('SwiftDragon193', '610ps2', 'SwiftDragon193@gmail.com', 'user'),
('SlyPanda832', 'xw6io5033yta', 'SlyPanda832@cpv2.com', 'user'),
('CalmCheetah963', '2o34v1rk7', 'CalmCheetah963@smile.sad', 'user'),
('QuickPanda766', 'k73phki78', 'QuickPanda766@cpv2.com', 'user'),
('GentleJaguar932', 'u1vhtfhu413n', 'GentleJaguar932@smile.sad', 'user'),
('QuietDragon295', '8831o7ku47', 'QuietDragon295@cpv2.com', 'user'),
('LazyPanda116', 'd351v3818abs', 'LazyPanda116@cpv2.com', 'user'),
('QuickRaven333', '61sgp65mcgq', 'QuickRaven333@gmail.com', 'user'),
('StrongRaven4', '3dn45moc636', 'StrongRaven4@gmail.com', 'user'),
('CleverCheetah597', 'ysw1pq', 'CleverCheetah597@cpv2.com', 'user'),
('HappyRaven293', '230f9gw', 'HappyRaven293@smile.sad', 'user'),
('BoldViper177', '72grw84752', 'BoldViper177@gmail.com', 'user'),
('QuickFox746', 'nz36915', 'QuickFox746@gmail.com', 'user'),
('BraveOtter335', 'sq5q6zrqs', 'BraveOtter335@akame.eris', 'user'),
('SlyRaven636', 'cx48294', 'SlyRaven636@gmail.com', 'user'),
('BrightLion186', '7qeh2tjc8', 'BrightLion186@cpv2.com', 'user'),
('LazyEagle40', 'u1dkpu4', 'LazyEagle40@cpv2.com', 'user'),
('LazyDragon50', 't26j59', 'LazyDragon50@cpv2.com', 'user'),
('FierceLion837', 'bgx930', 'FierceLion837@gmail.com', 'user'),
('CleverPanther341', '45dtjle', 'CleverPanther341@smile.sad', 'user'),
('FierceCheetah124', 'mob07l4', 'FierceCheetah124@smile.sad', 'user'),
('GentleBear383', '80ov09e6m0t', 'GentleBear383@akame.eris', 'user'),
('MightyEagle267', '58b11i63', 'MightyEagle267@akame.eris', 'user'),
('HappyPanther652', 'w9dne2t76pq', 'HappyPanther652@cpv2.com', 'user'),
('DarkEagle944', 'nlc46e35', 'DarkEagle944@smile.sad', 'user'),
('LoyalBadger716', 'm70yuy', 'LoyalBadger716@gmail.com', 'user'),
('LoyalPanther196', 'yt7uvf089', 'LoyalPanther196@akame.eris', 'user'),
('BoldBear394', 'xjan5vhe7g6', 'BoldBear394@cpv2.com', 'user'),
('BrightBear509', 'm2a6j8', 'BrightBear509@smile.sad', 'user'),
('BraveViper72', 'tbwa6z813f65', 'BraveViper72@cpv2.com', 'user'),
('GentleViper514', 'q59otr1f35', 'GentleViper514@cpv2.com', 'user'),
('LoyalFalcon410', 'k3aa4496', 'LoyalFalcon410@cpv2.com', 'user'),
('CalmViper495', 'bu77d9c8', 'CalmViper495@smile.sad', 'user'),
('CleverFox755', 'uq3ud4', 'CleverFox755@akame.eris', 'user'),
('MightyLeopard287', 'jhck1kzr32yd', 'MightyLeopard287@gmail.com', 'user'),
('BraveDragon172', 'z3mb459', 'BraveDragon172@gmail.com', 'user'),
('BraveLion215', 'mnr40gr037', 'BraveLion215@smile.sad', 'user'),
('MightyFalcon411', 'qct1fv90jgqu', 'MightyFalcon411@gmail.com', 'user'),
('DarkRaven69', 'slp06tj', 'DarkRaven69@smile.sad', 'user'),
('DarkLion952', '2fk9qhg8o', 'DarkLion952@akame.eris', 'user'),
('SadLeopard17', '86v5q5p20', 'SadLeopard17@cpv2.com', 'user'),
('CleverViper48', '4gai8606r5zq', 'CleverViper48@gmail.com', 'user'),
('GentleFox121', 'sfe4338c6xa', 'GentleFox121@cpv2.com', 'user'),
('MightyRaven940', '0377kxz', 'MightyRaven940@gmail.com', 'user'),
('LazyBear801', 'f8oh1e50ze', 'LazyBear801@gmail.com', 'user'),
('ShyViper629', 'ef8y3l863p', 'ShyViper629@cpv2.com', 'user'),
('CleverDragon367', 'dar5kl', 'CleverDragon367@cpv2.com', 'user'),
('DarkLeopard223', 'mxr05a2act29', 'DarkLeopard223@gmail.com', 'user'),
('SadHawk885', '46wa9j6ykbd4', 'SadHawk885@akame.eris', 'user'),
('SlyBear25', 'e61767f', 'SlyBear25@akame.eris', 'user'),
('FiercePanda106', '36490lldy', 'FiercePanda106@cpv2.com', 'user'),
('QuickLion642', '9hen4fop89c', 'QuickLion642@smile.sad', 'user'),
('StrongDragon772', '1ebhftf6m04x', 'StrongDragon772@gmail.com', 'user'),
('BoldBear666', '2w8ba99', 'BoldBear666@akame.eris', 'user'),
('WildFalcon795', '085y73nw09d', 'WildFalcon795@smile.sad', 'user'),
('CleverFox167', '6j1t5257z0r', 'CleverFox167@gmail.com', 'user'),
('BrightJaguar321', 'x1j9jjxk696', 'BrightJaguar321@akame.eris', 'user'),
('SadLeopard886', 'b286v9p35r95', 'SadLeopard886@gmail.com', 'user'),
('SlyTiger221', 'qoa35y4a', 'SlyTiger221@akame.eris', 'user'),
('DarkOtter224', '3339a436', 'DarkOtter224@smile.sad', 'user'),
('ShyShark293', '38lrex4gbf', 'ShyShark293@akame.eris', 'user'),
('LoyalHawk534', 'x4uy670m1i1', 'LoyalHawk534@gmail.com', 'user'),
('LoyalLion121', 'zh3u5v0', 'LoyalLion121@akame.eris', 'user'),
('SlyJaguar68', '734w3gdor', 'SlyJaguar68@cpv2.com', 'user'),
('SwiftDragon281', '21bh23oz0go', 'SwiftDragon281@akame.eris', 'user'),
('LazyHawk613', 'x8xe70339h', 'LazyHawk613@smile.sad', 'user'),
('StrongOtter771', '7via76', 'StrongOtter771@cpv2.com', 'user'),
('CalmLion341', '8nm6h46fkkz', 'CalmLion341@gmail.com', 'user'),
('CleverDragon288', 's679f68aci', 'CleverDragon288@cpv2.com', 'user'),
('CleverShark375', '29140y7xm', 'CleverShark375@akame.eris', 'user'),
('QuietDragon957', '55n934j8', 'QuietDragon957@smile.sad', 'user'),
('SadRaven856', '0rsu6b93pl', 'SadRaven856@akame.eris', 'user'),
('BoldJaguar396', 'w0r32e', 'BoldJaguar396@akame.eris', 'user'),
('QuickFalcon876', 'sm55dy83614', 'QuickFalcon876@smile.sad', 'user'),
('BrightBear605', '9zsi5i9xy', 'BrightBear605@smile.sad', 'user'),
('StrongOtter101', '5l34071p5t', 'StrongOtter101@smile.sad', 'user'),
('BrightBadger475', 'k3ygovv49l', 'BrightBadger475@gmail.com', 'user'),
('BoldDragon157', '465f08g', 'BoldDragon157@akame.eris', 'user'),
('SadRaven499', '507k18', 'SadRaven499@akame.eris', 'user'),
('HappyShark136', '2jpbp3ez', 'HappyShark136@akame.eris', 'user'),
('FierceFalcon721', 'e89z7px7', 'FierceFalcon721@cpv2.com', 'user'),
('FierceFalcon865', '764yje9', 'FierceFalcon865@smile.sad', 'user'),
('SwiftEagle290', 'vw7r6vh7zux1', 'SwiftEagle290@gmail.com', 'user'),
('StrongShark889', 'm6bq18', 'StrongShark889@gmail.com', 'user'),
('BraveFox784', 'vkwe3054t', 'BraveFox784@gmail.com', 'user'),
('GentleWolf861', '3o129ilt', 'GentleWolf861@smile.sad', 'user'),
('SadJaguar337', '541epo761tt', 'SadJaguar337@smile.sad', 'user'),
('BoldOtter565', '5vt1zwx0anb1', 'BoldOtter565@gmail.com', 'user'),
('FierceCobra776', '83gjz13rr2ay', 'FierceCobra776@cpv2.com', 'user'),
('SlyFox907', 'z8328kaow4s', 'SlyFox907@smile.sad', 'user'),
('LoyalHawk26', '6h8a995w', 'LoyalHawk26@gmail.com', 'user'),
('CleverWolf989', 'vim8we4cc', 'CleverWolf989@gmail.com', 'user'),
('SadCheetah766', 'o153cu0', 'SadCheetah766@akame.eris', 'user'),
('BraveBadger940', 'n02g24wwv', 'BraveBadger940@cpv2.com', 'user'),
('SadOtter496', 'o1te43wpznpr', 'SadOtter496@smile.sad', 'user'),
('HappyWolf516', 'b8gc36', 'HappyWolf516@akame.eris', 'user'),
('BravePanda12', '085xjmbo', 'BravePanda12@smile.sad', 'user'),
('DarkPanther849', '984mm9ti10f', 'DarkPanther849@cpv2.com', 'user'),
('ShyOtter485', 'lq44iv0zhq', 'ShyOtter485@gmail.com', 'user'),
('QuietFalcon804', 'jwg1cz54hdl', 'QuietFalcon804@gmail.com', 'user'),
('BoldFalcon967', 'j6f3bo3', 'BoldFalcon967@gmail.com', 'user'),
('BrightOtter157', 'r8s79nj7z', 'BrightOtter157@gmail.com', 'user'),
('FierceLion369', 'u8p6h3zt', 'FierceLion369@smile.sad', 'user'),
('CleverCobra658', 'y8xoi0vv08', 'CleverCobra658@cpv2.com', 'user'),
('LoyalRaven695', '9eo32f0', 'LoyalRaven695@smile.sad', 'user'),
('MightyShark375', 'rwwfqgbcd0j', 'MightyShark375@gmail.com', 'user'),
('BravePanda779', 'glk1l2idrjb', 'BravePanda779@cpv2.com', 'user'),
('WildRaven952', 'rgnrvn8e4', 'WildRaven952@akame.eris', 'user'),
('CleverLeopard768', '40745569n', 'CleverLeopard768@cpv2.com', 'user'),
('HappyEagle53', 'r39ev3via', 'HappyEagle53@smile.sad', 'user'),
('HappyCobra456', '7101bl3', 'HappyCobra456@akame.eris', 'user'),
('QuietCheetah28', 'e6827e', 'QuietCheetah28@akame.eris', 'user'),
('GentleLeopard85', 'uhnlh4yw1ex6', 'GentleLeopard85@gmail.com', 'user'),
('SwiftJaguar974', 'w383a5gnk', 'SwiftJaguar974@gmail.com', 'user'),
('CalmDragon919', '86ng704qn', 'CalmDragon919@akame.eris', 'user'),
('LazyOtter855', 'b15co71tdrn', 'LazyOtter855@akame.eris', 'user'),
('HappyWolf173', 'ko8yhw418s', 'HappyWolf173@gmail.com', 'user'),
('CalmPanther141', '50bdxy82088', 'CalmPanther141@gmail.com', 'user'),
('BrightFox477', 'x88g3l9q1fih', 'BrightFox477@gmail.com', 'user'),
('CalmFalcon322', 'g9dtdz1ajd', 'CalmFalcon322@cpv2.com', 'user'),
('LazyEagle633', '0cy4j0guhy31', 'LazyEagle633@akame.eris', 'user'),
('GentleViper405', 'b9c136yo', 'GentleViper405@gmail.com', 'user'),
('StrongLion243', 'tmdkm189t38', 'StrongLion243@cpv2.com', 'user'),
('CalmDragon93', 'v97xs23', 'CalmDragon93@akame.eris', 'user'),
('WildViper828', 'mr5temw', 'WildViper828@smile.sad', 'user'),
('ShyFalcon12', '22qgtkby', 'ShyFalcon12@smile.sad', 'user'),
('QuickHawk730', '3r95c27g7qjd', 'QuickHawk730@cpv2.com', 'user'),
('SlyWolf329', 'o8y162r5', 'SlyWolf329@akame.eris', 'user'),
('WildBear295', '6d3cs3z3', 'WildBear295@cpv2.com', 'user'),
('CalmLion934', 'xcl68m', 'CalmLion934@gmail.com', 'user'),
('BraveLion561', 'm97pq51', 'BraveLion561@akame.eris', 'user'),
('GentlePanda634', '7t6j5ze', 'GentlePanda634@gmail.com', 'user'),
('MightyPanther403', '5hi603', 'MightyPanther403@smile.sad', 'user'),
('SadShark721', 'c7318z', 'SadShark721@smile.sad', 'user'),
('QuietViper328', '4rnk1joo', 'QuietViper328@smile.sad', 'user'),
('SadPanther291', 'dwe9n4sap8', 'SadPanther291@cpv2.com', 'user'),
('FierceFalcon936', 'fq4qk2a7', 'FierceFalcon936@smile.sad', 'user'),
('HappyEagle630', '08720tt0t76', 'HappyEagle630@gmail.com', 'user'),
('MightyWolf973', 'gqqj33fk5n', 'MightyWolf973@cpv2.com', 'user'),
('DarkViper335', 'fnfcte6jd', 'DarkViper335@gmail.com', 'user'),
('BoldShark587', '3op2zzt788lz', 'BoldShark587@akame.eris', 'user'),
('DarkHawk221', '6y8zav', 'DarkHawk221@smile.sad', 'user'),
('StrongFox409', '0p3rqyoo', 'StrongFox409@cpv2.com', 'user'),
('SlyDragon289', '8535514ki93', 'SlyDragon289@smile.sad', 'user'),
('BraveRaven7', '6267j0561', 'BraveRaven7@gmail.com', 'user'),
('QuickJaguar466', '49eqi0fgst', 'QuickJaguar466@akame.eris', 'user'),
('QuickFox39', '883w244', 'QuickFox39@smile.sad', 'user'),
('BoldPanther390', '8k0aidqa4', 'BoldPanther390@smile.sad', 'user'),
('DarkPanda975', '2000u86', 'DarkPanda975@akame.eris', 'user'),
('WildPanda488', 'y575gc', 'WildPanda488@gmail.com', 'user'),
('QuietPanther195', 'dd0tjq', 'QuietPanther195@akame.eris', 'user'),
('BraveFox256', 's7sj07cq68', 'BraveFox256@gmail.com', 'user'),
('ShyPanther924', 'cpz44gnf7', 'ShyPanther924@akame.eris', 'user'),
('StrongPanda635', 'n32qngu1ys', 'StrongPanda635@akame.eris', 'user'),
('CalmShark656', 'zh4nbfiv', 'CalmShark656@gmail.com', 'user'),
('CalmBadger81', 'p57o36wyr37', 'CalmBadger81@akame.eris', 'user'),
('FierceBadger673', 'do8xqi', 'FierceBadger673@cpv2.com', 'user'),
('SlyLion736', '03rsb0', 'SlyLion736@smile.sad', 'user'),
('FierceHawk149', '04232ag52i1', 'FierceHawk149@gmail.com', 'user'),
('BoldCheetah462', 'j55c2j', 'BoldCheetah462@cpv2.com', 'user'),
('SwiftBadger394', 'b4tf80r4', 'SwiftBadger394@cpv2.com', 'user'),
('QuietJaguar69', 'u660drv9al', 'QuietJaguar69@smile.sad', 'user'),
('GentleBear926', 'cz1l1yqlsx3m', 'GentleBear926@cpv2.com', 'user'),
('BravePanda851', '6ckn1a3', 'BravePanda851@smile.sad', 'user'),
('LazyPanda868', 'ba4rc2', 'LazyPanda868@gmail.com', 'user'),
('QuietJaguar324', 'z5r5n9', 'QuietJaguar324@smile.sad', 'user'),
('SlyCheetah207', '14nw3qo0', 'SlyCheetah207@smile.sad', 'user'),
('ShyPanther254', 'ix84gg54fbz9', 'ShyPanther254@smile.sad', 'user'),
('CalmPanther210', 'ff8txhy0', 'CalmPanther210@cpv2.com', 'user'),
('ShyHawk238', 'h90go37g', 'ShyHawk238@gmail.com', 'user'),
('WildCheetah475', 'w9p9oq4vrv', 'WildCheetah475@smile.sad', 'user'),
('QuickHawk767', '9ppxeux5v4i0', 'QuickHawk767@akame.eris', 'user'),
('QuickCheetah593', 'ikh675lwn', 'QuickCheetah593@gmail.com', 'user'),
('StrongBear614', 'cdjk04r47v0p', 'StrongBear614@akame.eris', 'user'),
('LazyEagle788', '1tx9q385q3q3', 'LazyEagle788@cpv2.com', 'user'),
('BoldViper947', '98627m3ya', 'BoldViper947@akame.eris', 'user'),
('SadCheetah604', '5lju9f', 'SadCheetah604@cpv2.com', 'user'),
('SlyFalcon308', 'e9whm63315s', 'SlyFalcon308@cpv2.com', 'user'),
('ShyCobra497', '06656s', 'ShyCobra497@gmail.com', 'user'),
('StrongCobra781', 'fjj58bwv', 'StrongCobra781@gmail.com', 'user'),
('MightyJaguar329', '4ymd7v8y7', 'MightyJaguar329@cpv2.com', 'user'),
('WildLion731', 'i9ncy1zj81l', 'WildLion731@cpv2.com', 'user'),
('WildLeopard586', '739kql', 'WildLeopard586@smile.sad', 'user'),
('GentleTiger131', '8hf1tt8b4u64', 'GentleTiger131@gmail.com', 'user'),
('CalmPanther874', 'xxm318g32qj', 'CalmPanther874@gmail.com', 'user'),
('CalmOtter223', 'pt88hx7', 'CalmOtter223@cpv2.com', 'user'),
('MightyJaguar315', '2t0004k58e5', 'MightyJaguar315@smile.sad', 'user'),
('LazyShark19', '8u5a08', 'LazyShark19@smile.sad', 'user'),
('BraveCheetah564', 'j23909t8', 'BraveCheetah564@smile.sad', 'user'),
('BoldBear653', '0n958q6', 'BoldBear653@smile.sad', 'user'),
('DarkFox939', 'hj33lzd0', 'DarkFox939@smile.sad', 'user'),
('DarkJaguar776', 'anys7a75g1', 'DarkJaguar776@smile.sad', 'user'),
('BrightCobra932', 't5wie34i48', 'BrightCobra932@akame.eris', 'user'),
('StrongTiger940', 'e41962401p', 'StrongTiger940@cpv2.com', 'user'),
('GentleLeopard908', '5748b61', 'GentleLeopard908@smile.sad', 'user'),
('DarkCobra795', 'prr366dzlr8', 'DarkCobra795@cpv2.com', 'user'),
('MightyRaven41', '94s0r0784r', 'MightyRaven41@gmail.com', 'user'),
('HappyCheetah91', 'j13y8dn4q8r', 'HappyCheetah91@gmail.com', 'user'),
('CleverShark578', 'h32a3555', 'CleverShark578@cpv2.com', 'user'),
('SlyTiger541', '63f439354dv9', 'SlyTiger541@akame.eris', 'user'),
('LoyalHawk309', 'f59456r556', 'LoyalHawk309@akame.eris', 'user'),
('LazyLeopard850', '8ukq6dz', 'LazyLeopard850@gmail.com', 'user'),
('WildHawk128', 'u159784e6g', 'WildHawk128@gmail.com', 'user'),
('CleverEagle629', 't738f76', 'CleverEagle629@smile.sad', 'user'),
('SadDragon335', 'c93w8rbb1g', 'SadDragon335@smile.sad', 'user'),
('LazyCheetah511', '94nk0t', 'LazyCheetah511@gmail.com', 'user'),
('CalmViper811', '64nerq228nw', 'CalmViper811@akame.eris', 'user'),
('CleverJaguar784', '6rc61e358ml', 'CleverJaguar784@gmail.com', 'user'),
('CleverWolf878', 'v648q4s18', 'CleverWolf878@smile.sad', 'user'),
('SlyRaven771', 'adz17vfp7lr', 'SlyRaven771@cpv2.com', 'user'),
('BoldHawk4', 'yqe1y37', 'BoldHawk4@smile.sad', 'user'),
('WildCobra626', 'j2smlt20', 'WildCobra626@smile.sad', 'user'),
('CalmOtter984', '1s53w4315', 'CalmOtter984@cpv2.com', 'user'),
('StrongRaven86', '4n57110lwv', 'StrongRaven86@akame.eris', 'user'),
('MightyTiger754', 'v85kp822fd18', 'MightyTiger754@cpv2.com', 'user'),
('CalmViper854', 'wt2f6qq6', 'CalmViper854@cpv2.com', 'user'),
('SadBear273', 'wg0tvz6vod', 'SadBear273@akame.eris', 'user'),
('StrongCheetah86', 'scga1gqisn6', 'StrongCheetah86@cpv2.com', 'user'),
('SlyHawk389', 'tow01i46', 'SlyHawk389@akame.eris', 'user'),
('MightyBear114', 'x095vd', 'MightyBear114@cpv2.com', 'user'),
('BraveViper988', 'a5fwbn', 'BraveViper988@cpv2.com', 'user'),
('WildJaguar438', 'u4aufet9v4', 'WildJaguar438@cpv2.com', 'user'),
('StrongFox751', 'rfr9skgh12', 'StrongFox751@akame.eris', 'user'),
('CalmPanther854', '2rv660nwn', 'CalmPanther854@gmail.com', 'user'),
('StrongLion552', '8s8c25', 'StrongLion552@gmail.com', 'user'),
('LoyalViper79', 'm5qu79is9t', 'LoyalViper79@smile.sad', 'user'),
('FierceTiger598', '27v1g929', 'FierceTiger598@gmail.com', 'user'),
('SadBear423', '990n89fqe242', 'SadBear423@smile.sad', 'user'),
('DarkOtter232', 'tno222ig', 'DarkOtter232@gmail.com', 'user'),
('SadFalcon62', 'f4590534bg8', 'SadFalcon62@gmail.com', 'user'),
('SadBear771', 'anq36k4', 'SadBear771@akame.eris', 'user'),
('QuietHawk803', 'tp6xvt90fo', 'QuietHawk803@cpv2.com', 'user'),
('CalmFalcon527', '25izo96', 'CalmFalcon527@gmail.com', 'user'),
('FierceFox97', 'dhxrxb7s', 'FierceFox97@akame.eris', 'user'),
('CalmOtter877', 'ggg6mvcn', 'CalmOtter877@akame.eris', 'user'),
('CalmCheetah472', 'p0m70fp6312', 'CalmCheetah472@cpv2.com', 'user'),
('HappyEagle82', 's3q8ld', 'HappyEagle82@smile.sad', 'user'),
('FierceJaguar80', '434cn9h90c', 'FierceJaguar80@cpv2.com', 'user'),
('FierceShark267', '99zqizd', 'FierceShark267@akame.eris', 'user'),
('HappyEagle959', '3yzkcj', 'HappyEagle959@cpv2.com', 'user'),
('StrongBadger542', 'avwu8cb9504', 'StrongBadger542@smile.sad', 'user'),
('MightyTiger966', 'hf1ri46j33d0', 'MightyTiger966@gmail.com', 'user'),
('DarkLion612', 'a55x5b4', 'DarkLion612@gmail.com', 'user'),
('LazyBear673', 'i7b4i0at2u', 'LazyBear673@cpv2.com', 'user'),
('StrongFalcon491', 'jsgr777r0sxw', 'StrongFalcon491@gmail.com', 'user'),
('MightyLion542', '995x80ni7799', 'MightyLion542@smile.sad', 'user'),
('BrightPanda128', 'srorrj94', 'BrightPanda128@gmail.com', 'user'),
('QuickCobra531', '93cx87bt', 'QuickCobra531@smile.sad', 'user'),
('MightyEagle959', '589rqgif', 'MightyEagle959@smile.sad', 'user'),
('WildEagle66', 'b69ikz33b5a', 'WildEagle66@cpv2.com', 'user'),
('WildLion224', 'kqba3qo3', 'WildLion224@smile.sad', 'user'),
('FierceLion18', '9nk952ruf', 'FierceLion18@akame.eris', 'user'),
('StrongWolf659', '6u0oxidni006', 'StrongWolf659@smile.sad', 'user'),
('SadHawk420', 'g01015r35', 'SadHawk420@smile.sad', 'user'),
('QuietFalcon451', 'gw66313', 'QuietFalcon451@gmail.com', 'user'),
('BoldPanda973', '44oizq', 'BoldPanda973@cpv2.com', 'user'),
('SwiftBadger208', '7is515', 'SwiftBadger208@gmail.com', 'user');

insert into topics(topic_name) values
('combinatorics'),
('recurrences'),
('graphs'),
('graph coloring'),
('numer theory'),
('constructive'),
('long output'),
('calculus'),
('equations'),
('geometry'),
('yes/no');
insert into announcements(title, content, date_posted) values
('We would like to invite you to another Weekend Practice Contest #1', 'You will be given a 5-10 problems to solve in 2-4 hours.
Ranking for the contest will be distributed after the ending.
Everyone can participate. 
Good luck.', '2024-09-01 16:35:00'::timestamp - interval '84 days'),
('We would like to invite you to another Weekend Practice Contest #2', 'You will be given a 5-10 problems to solve in 2-4 hours.
Ranking for the contest will be distributed after the ending.
Everyone can participate. 
Good luck.', '2024-09-01 16:35:00'::timestamp - interval '70 days'),
('We would like to invite you to another Weekend Practice Contest #3', 'You will be given a 5-10 problems to solve in 2-4 hours.
Ranking for the contest will be distributed after the ending.
Everyone can participate. 
Good luck.', '2024-09-01 16:35:00'::timestamp - interval '56 days'),
('We would like to invite you to another Weekend Practice Contest #4', 'You will be given a 5-10 problems to solve in 2-4 hours.
Ranking for the contest will be distributed after the ending.
Everyone can participate. 
Good luck.', '2024-09-01 16:35:00'::timestamp - interval '42 days'),
('We would like to invite you to another Weekend Practice Contest #5', 'You will be given a 5-10 problems to solve in 2-4 hours.
Ranking for the contest will be distributed after the ending.
Everyone can participate. 
Good luck.', '2024-09-01 16:35:00'::timestamp - interval '28 days'),
('We would like to invite you to another Weekend Practice Contest #6', 'You will be given a 5-10 problems to solve in 2-4 hours.
Ranking for the contest will be distributed after the ending.
Everyone can participate. 
Good luck.', '2024-09-01 16:35:00'::timestamp - interval '14 days');

insert into announcements(title, content, date_posted) values
('Welcome to CPv2.', 'Here you are able to solve different problems and participate in the contests in real time', '2024-05-23 23:21:45'::timestamp);


insert into announcements(title, content, date_posted) values
('Jagiellonian University MD contest', 'We invite you to specific contest. It is supposed for students of Jagiellonian university, but still, everyone can participate. The problems will be related with discrete mathematics.', '2024-07-02 14:02:09'::timestamp);

insert into problems(statement, answer, output_only) values
('find the number of primes up to 10', '4', 'true'),
('find the value of binom(5, 0)+binom(5, 1)+...+binom(5, 5)', '32', 'true'),
('what is the value of 0xor1xor2xor...xor100?', '100', 'true'),
('is that true, that the 3-regular graph with hamiltonian cycle is edge-three-colorable?', 'yes', 'true'),
('what is the determinant of the matrix
3 0 0
9 2 0
8 8 8
?', '48', 'true'),
('find the value of 1+2+3+4+...+50', '1275', 'yes'),
('check whether the grid graph with vertex a connected to all other vertices is planar', 'no', 'true'),
('how many permutations on 6 elements with one cycle exists?', '120', 'true'),
('does finding the hamiltonian path is NP hard?', 'yes', 'true'),
('find the Ramsey number R(3, 3)', '6', 'true'),
('is that true that x(G) > col(G)?', 'no', 'true'),
('what is the maximal value of the б(G), if the planar graph has no triangles', '3', 'true'),
('what is the maximal value of the б(G)', '5', 'true'),
('count the number of labeled trees on 4 vertices', '16', 'true');
insert into contests(contest_name, start_time, end_time, description, is_active) values
('Weekend Practice #1', '2024-09-01 16:35:00'::timestamp - interval '84 days',
 '2024-09-01 18:35:00'::timestamp - interval '84 days', 'first practice contest for all participants', 'false'),
('Weekend Practice #2', '2024-09-01 16:35:00'::timestamp - interval '70 days',
 '2024-09-01 18:35:00'::timestamp - interval '70 days', 'second practice contest for all participants', 'false'),
('Weekend Practice #3', '2024-09-01 16:35:00'::timestamp - interval '56 days',
 '2024-09-01 18:35:00'::timestamp - interval '56 days', 'third practice contest for all participants', 'false'),
('Weekend Practice #4', '2024-09-01 16:35:00'::timestamp - interval '42 days',
 '2024-09-01 18:35:00'::timestamp - interval '42 days', 'forth practice contest for all participants', 'false'),
('Weekend Practice #5', '2024-09-01 16:35:00'::timestamp - interval '28 days',
 '2024-09-01 18:35:00'::timestamp - interval '28 days', 'fifth practice contest for all participants', 'false'),
('Weekend Practice #6', '2024-09-01 16:35:00'::timestamp - interval '14 days',
 '2024-09-01 18:35:00'::timestamp - interval '14 days', 'sixth practice contest for all participants', 'false'),
('Jagiellonian MD contest', '2024-07-05 10:00:00'::timestamp,
 '2024-07-06 10:00:00'::timestamp, 'MD contest covers all topics during semester', 'false');
insert into contest_announcements(contest_id, announcement_id) values
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6);
insert into contest_problems(contest_id, problem_id) values
(1, 1),
(1, 2),
(1, 3),
(2, 4),
(2, 5),
(2, 6),
(3, 7),
(3, 8),
(3, 9),
(4, 1),
(4, 5),
(4, 2),
(5, 4),
(5, 7),
(5, 10),
(6, 3),
(6, 8),
(6, 1),
(7, 2),
(7, 4),
(7, 7),
(7, 10);
insert into contest_participants(contest_id, user_id, score, rank) values
(3, 35, 0, 1),
(1, 274, 0, 1),
(2, 242, 0, 1),
(4, 276, 0, 1),
(6, 181, 0, 1),
(6, 373, 0, 1),
(1, 124, 0, 1),
(1, 55, 0, 1),
(2, 193, 0, 1),
(1, 294, 0, 1),
(2, 237, 0, 1),
(3, 173, 0, 1),
(4, 153, 0, 1),
(3, 162, 0, 1),
(1, 257, 0, 1),
(3, 256, 0, 1),
(1, 205, 0, 1),
(3, 335, 0, 1),
(1, 308, 0, 1),
(3, 378, 0, 1),
(4, 267, 0, 1),
(6, 201, 0, 1),
(4, 269, 0, 1),
(6, 123, 0, 1),
(1, 37, 0, 1),
(5, 211, 0, 1),
(6, 378, 0, 1),
(3, 225, 0, 1),
(5, 12, 0, 1),
(1, 11, 0, 1),
(5, 4, 0, 1),
(4, 106, 0, 1),
(5, 349, 0, 1),
(2, 274, 0, 1),
(2, 295, 0, 1),
(2, 157, 0, 1),
(1, 386, 0, 1),
(6, 286, 0, 1),
(4, 381, 0, 1),
(6, 274, 0, 1),
(2, 240, 0, 1),
(4, 147, 0, 1),
(6, 126, 0, 1),
(6, 374, 0, 1),
(3, 334, 0, 1),
(2, 30, 0, 1),
(6, 169, 0, 1),
(4, 27, 0, 1),
(4, 258, 0, 1),
(6, 388, 0, 1),
(3, 30, 0, 1),
(2, 306, 0, 1),
(4, 166, 0, 1),
(6, 41, 0, 1),
(5, 361, 0, 1),
(2, 62, 0, 1),
(6, 331, 0, 1),
(3, 321, 0, 1),
(3, 172, 0, 1),
(1, 379, 0, 1),
(4, 247, 0, 1),
(4, 256, 0, 1),
(5, 206, 0, 1),
(3, 177, 0, 1),
(3, 391, 0, 1),
(1, 321, 0, 1),
(5, 371, 0, 1),
(2, 232, 0, 1),
(6, 245, 0, 1),
(3, 47, 0, 1),
(6, 119, 0, 1),
(5, 17, 0, 1),
(1, 86, 0, 1),
(4, 390, 0, 1),
(5, 134, 0, 1),
(6, 195, 0, 1),
(5, 394, 0, 1),
(2, 201, 0, 1),
(4, 288, 0, 1),
(2, 36, 0, 1),
(1, 83, 0, 1),
(1, 166, 0, 1),
(6, 253, 0, 1),
(2, 297, 0, 1),
(1, 231, 0, 1),
(5, 159, 0, 1),
(1, 199, 0, 1),
(4, 240, 0, 1),
(1, 99, 0, 1),
(5, 101, 0, 1),
(5, 43, 0, 1),
(6, 178, 0, 1),
(3, 260, 0, 1),
(5, 390, 0, 1),
(6, 78, 0, 1),
(5, 71, 0, 1),
(3, 259, 0, 1),
(5, 384, 0, 1),
(1, 219, 0, 1),
(5, 281, 0, 1),
(3, 312, 0, 1),
(3, 217, 0, 1),
(1, 195, 0, 1),
(1, 74, 0, 1),
(3, 228, 0, 1),
(2, 8, 0, 1),
(2, 248, 0, 1),
(4, 344, 0, 1),
(3, 60, 0, 1),
(4, 348, 0, 1),
(4, 43, 0, 1),
(5, 306, 0, 1),
(3, 287, 0, 1),
(3, 363, 0, 1),
(6, 293, 0, 1),
(4, 400, 0, 1),
(4, 262, 0, 1),
(6, 143, 0, 1),
(6, 387, 0, 1),
(1, 118, 0, 1),
(1, 324, 0, 1),
(6, 53, 0, 1),
(2, 180, 0, 1),
(1, 26, 0, 1),
(6, 231, 0, 1),
(6, 384, 0, 1),
(4, 109, 0, 1),
(1, 366, 0, 1),
(1, 352, 0, 1),
(5, 66, 0, 1),
(3, 55, 0, 1),
(6, 271, 0, 1),
(3, 109, 0, 1),
(3, 154, 0, 1),
(2, 158, 0, 1),
(3, 184, 0, 1),
(6, 130, 0, 1),
(6, 21, 0, 1),
(1, 119, 0, 1),
(2, 228, 0, 1),
(2, 367, 0, 1),
(1, 80, 0, 1),
(6, 144, 0, 1),
(1, 302, 0, 1),
(3, 338, 0, 1),
(3, 108, 0, 1),
(4, 163, 0, 1),
(4, 78, 0, 1),
(6, 234, 0, 1),
(5, 240, 0, 1),
(2, 75, 0, 1),
(5, 130, 0, 1),
(4, 120, 0, 1),
(1, 97, 0, 1),
(5, 293, 0, 1),
(1, 186, 0, 1),
(2, 57, 0, 1),
(3, 370, 0, 1),
(5, 397, 0, 1),
(2, 218, 0, 1),
(1, 14, 0, 1),
(3, 176, 0, 1),
(4, 292, 0, 1),
(1, 135, 0, 1),
(3, 26, 0, 1),
(3, 201, 0, 1),
(2, 153, 0, 1),
(1, 363, 0, 1),
(1, 116, 0, 1),
(5, 377, 0, 1),
(2, 64, 0, 1),
(1, 131, 0, 1),
(6, 95, 0, 1),
(2, 143, 0, 1),
(1, 40, 0, 1),
(4, 252, 0, 1),
(6, 24, 0, 1),
(2, 169, 0, 1),
(1, 375, 0, 1),
(3, 346, 0, 1),
(4, 227, 0, 1),
(5, 292, 0, 1),
(4, 10, 0, 1),
(1, 316, 0, 1),
(4, 316, 0, 1),
(3, 373, 0, 1),
(4, 207, 0, 1),
(6, 223, 0, 1),
(1, 364, 0, 1),
(3, 219, 0, 1),
(6, 34, 0, 1),
(5, 91, 0, 1),
(6, 165, 0, 1),
(6, 90, 0, 1),
(1, 9, 0, 1),
(5, 39, 0, 1),
(5, 55, 0, 1),
(1, 130, 0, 1),
(2, 32, 0, 1),
(3, 223, 0, 1),
(5, 70, 0, 1),
(4, 289, 0, 1),
(5, 35, 0, 1),
(4, 368, 0, 1),
(2, 313, 0, 1),
(2, 71, 0, 1),
(3, 24, 0, 1),
(5, 67, 0, 1),
(4, 28, 0, 1),
(2, 33, 0, 1),
(2, 235, 0, 1),
(4, 384, 0, 1),
(6, 358, 0, 1),
(5, 199, 0, 1),
(3, 331, 0, 1),
(1, 184, 0, 1),
(3, 247, 0, 1),
(3, 57, 0, 1),
(4, 282, 0, 1),
(4, 35, 0, 1),
(5, 398, 0, 1),
(6, 191, 0, 1),
(6, 76, 0, 1),
(2, 160, 0, 1),
(2, 209, 0, 1),
(5, 218, 0, 1),
(4, 290, 0, 1),
(4, 162, 0, 1),
(4, 4, 0, 1),
(5, 1, 0, 1),
(5, 334, 0, 1),
(5, 138, 0, 1),
(6, 313, 0, 1),
(6, 392, 0, 1),
(6, 150, 0, 1),
(1, 260, 0, 1),
(2, 152, 0, 1),
(3, 375, 0, 1),
(1, 69, 0, 1),
(4, 111, 0, 1),
(2, 72, 0, 1),
(3, 388, 0, 1),
(4, 48, 0, 1),
(6, 385, 0, 1),
(1, 335, 0, 1),
(2, 256, 0, 1),
(1, 64, 0, 1),
(6, 13, 0, 1),
(2, 127, 0, 1),
(2, 285, 0, 1),
(5, 308, 0, 1),
(2, 137, 0, 1),
(5, 80, 0, 1),
(1, 70, 0, 1),
(5, 126, 0, 1),
(6, 396, 0, 1),
(1, 259, 0, 1),
(6, 389, 0, 1),
(2, 162, 0, 1),
(4, 167, 0, 1),
(1, 393, 0, 1),
(6, 167, 0, 1),
(4, 322, 0, 1),
(3, 251, 0, 1),
(6, 194, 0, 1),
(6, 19, 0, 1),
(5, 163, 0, 1),
(3, 194, 0, 1),
(3, 238, 0, 1),
(6, 229, 0, 1),
(2, 97, 0, 1),
(1, 171, 0, 1),
(3, 141, 0, 1),
(2, 284, 0, 1),
(2, 350, 0, 1),
(1, 288, 0, 1),
(6, 200, 0, 1),
(6, 355, 0, 1),
(3, 211, 0, 1),
(1, 157, 0, 1),
(5, 359, 0, 1),
(1, 183, 0, 1),
(1, 145, 0, 1),
(4, 5, 0, 1),
(2, 374, 0, 1),
(3, 160, 0, 1),
(4, 183, 0, 1),
(6, 153, 0, 1),
(4, 302, 0, 1),
(5, 284, 0, 1),
(6, 48, 0, 1),
(6, 136, 0, 1),
(4, 327, 0, 1),
(3, 53, 0, 1),
(1, 95, 0, 1),
(3, 315, 0, 1),
(1, 355, 0, 1),
(1, 42, 0, 1),
(3, 268, 0, 1),
(6, 158, 0, 1),
(1, 117, 0, 1),
(1, 240, 0, 1),
(5, 360, 0, 1),
(2, 147, 0, 1),
(6, 240, 0, 1),
(2, 390, 0, 1),
(6, 127, 0, 1),
(5, 99, 0, 1),
(2, 146, 0, 1),
(2, 92, 0, 1),
(4, 248, 0, 1),
(3, 234, 0, 1),
(6, 222, 0, 1),
(6, 320, 0, 1),
(5, 128, 0, 1),
(6, 204, 0, 1),
(4, 362, 0, 1),
(3, 244, 0, 1),
(4, 339, 0, 1),
(6, 42, 0, 1),
(4, 129, 0, 1),
(2, 280, 0, 1),
(2, 243, 0, 1),
(6, 276, 0, 1),
(2, 206, 0, 1),
(2, 322, 0, 1),
(4, 57, 0, 1),
(6, 23, 0, 1),
(5, 180, 0, 1),
(6, 59, 0, 1),
(2, 271, 0, 1),
(4, 397, 0, 1),
(3, 32, 0, 1),
(5, 354, 0, 1),
(1, 194, 0, 1),
(4, 387, 0, 1),
(4, 272, 0, 1),
(3, 250, 0, 1),
(2, 211, 0, 1),
(2, 106, 0, 1),
(6, 45, 0, 1),
(2, 379, 0, 1),
(6, 283, 0, 1),
(1, 156, 0, 1),
(3, 39, 0, 1),
(1, 20, 0, 1),
(2, 142, 0, 1),
(2, 231, 0, 1),
(6, 284, 0, 1),
(4, 275, 0, 1),
(2, 49, 0, 1),
(1, 268, 0, 1),
(3, 183, 0, 1),
(4, 94, 0, 1),
(3, 117, 0, 1),
(5, 166, 0, 1),
(6, 174, 0, 1),
(5, 302, 0, 1),
(6, 171, 0, 1),
(2, 258, 0, 1),
(6, 111, 0, 1),
(6, 142, 0, 1),
(4, 298, 0, 1),
(5, 202, 0, 1),
(2, 122, 0, 1),
(2, 339, 0, 1),
(1, 188, 0, 1),
(5, 382, 0, 1),
(2, 395, 0, 1),
(1, 22, 0, 1),
(1, 122, 0, 1),
(5, 93, 0, 1),
(6, 337, 0, 1),
(1, 28, 0, 1),
(3, 156, 0, 1),
(6, 156, 0, 1),
(2, 38, 0, 1),
(2, 299, 0, 1),
(2, 378, 0, 1),
(4, 366, 0, 1),
(2, 23, 0, 1),
(5, 253, 0, 1),
(1, 212, 0, 1),
(4, 7, 0, 1),
(2, 130, 0, 1),
(5, 257, 0, 1),
(4, 194, 0, 1),
(5, 175, 0, 1),
(2, 332, 0, 1),
(5, 142, 0, 1),
(3, 308, 0, 1),
(1, 115, 0, 1),
(3, 279, 0, 1),
(1, 289, 0, 1),
(1, 269, 0, 1),
(4, 223, 0, 1),
(2, 267, 0, 1),
(5, 317, 0, 1),
(1, 392, 0, 1),
(4, 17, 0, 1),
(5, 303, 0, 1),
(5, 53, 0, 1),
(3, 362, 0, 1),
(4, 47, 0, 1),
(6, 96, 0, 1),
(3, 239, 0, 1),
(5, 232, 0, 1),
(5, 79, 0, 1),
(6, 304, 0, 1),
(1, 41, 0, 1),
(6, 28, 0, 1),
(1, 267, 0, 1),
(3, 14, 0, 1),
(5, 305, 0, 1),
(3, 146, 0, 1),
(2, 65, 0, 1),
(2, 336, 0, 1),
(6, 140, 0, 1),
(5, 239, 0, 1),
(4, 172, 0, 1),
(2, 294, 0, 1),
(6, 312, 0, 1),
(3, 48, 0, 1),
(6, 172, 0, 1),
(3, 355, 0, 1),
(3, 263, 0, 1),
(1, 323, 0, 1),
(3, 248, 0, 1),
(4, 80, 0, 1),
(4, 396, 0, 1),
(4, 237, 0, 1),
(6, 115, 0, 1),
(2, 173, 0, 1),
(1, 65, 0, 1),
(6, 74, 0, 1),
(3, 371, 0, 1),
(2, 246, 0, 1),
(6, 107, 0, 1),
(1, 46, 0, 1),
(2, 250, 0, 1),
(1, 215, 0, 1),
(5, 228, 0, 1),
(5, 165, 0, 1),
(4, 202, 0, 1),
(5, 137, 0, 1),
(1, 270, 0, 1),
(4, 392, 0, 1),
(1, 342, 0, 1),
(6, 205, 0, 1),
(3, 360, 0, 1),
(3, 107, 0, 1),
(4, 210, 0, 1),
(4, 287, 0, 1),
(2, 365, 0, 1),
(4, 358, 0, 1),
(5, 265, 0, 1),
(2, 134, 0, 1),
(5, 109, 0, 1),
(1, 332, 0, 1),
(2, 131, 0, 1),
(5, 133, 0, 1),
(1, 152, 0, 1),
(1, 192, 0, 1),
(4, 308, 0, 1),
(2, 359, 0, 1),
(6, 361, 0, 1),
(1, 326, 0, 1),
(3, 329, 0, 1),
(3, 19, 0, 1),
(2, 205, 0, 1),
(1, 255, 0, 1),
(5, 111, 0, 1),
(2, 144, 0, 1),
(3, 142, 0, 1),
(5, 282, 0, 1),
(4, 259, 0, 1),
(3, 276, 0, 1),
(5, 207, 0, 1),
(4, 320, 0, 1),
(4, 93, 0, 1),
(6, 49, 0, 1),
(5, 131, 0, 1),
(2, 6, 0, 1),
(3, 205, 0, 1),
(3, 202, 0, 1),
(6, 381, 0, 1),
(1, 204, 0, 1),
(6, 400, 0, 1),
(6, 303, 0, 1),
(5, 338, 0, 1),
(4, 20, 0, 1),
(1, 351, 0, 1),
(1, 356, 0, 1),
(6, 146, 0, 1),
(4, 332, 0, 1),
(2, 269, 0, 1),
(2, 252, 0, 1),
(1, 373, 0, 1),
(5, 224, 0, 1),
(5, 300, 0, 1),
(2, 136, 0, 1),
(5, 27, 0, 1),
(2, 59, 0, 1),
(6, 6, 0, 1),
(2, 328, 0, 1),
(4, 250, 0, 1),
(5, 263, 0, 1),
(1, 254, 0, 1),
(6, 25, 0, 1),
(6, 116, 0, 1),
(4, 180, 0, 1),
(1, 340, 0, 1),
(3, 124, 0, 1),
(1, 133, 0, 1),
(4, 152, 0, 1),
(5, 243, 0, 1),
(5, 326, 0, 1),
(5, 68, 0, 1),
(1, 251, 0, 1),
(3, 66, 0, 1),
(4, 25, 0, 1),
(4, 246, 0, 1),
(1, 209, 0, 1),
(3, 153, 0, 1),
(5, 22, 0, 1),
(4, 225, 0, 1),
(1, 77, 0, 1),
(1, 206, 0, 1),
(2, 298, 0, 1),
(2, 357, 0, 1),
(6, 43, 0, 1),
(3, 149, 0, 1),
(1, 167, 0, 1),
(5, 385, 0, 1),
(6, 85, 0, 1),
(1, 333, 0, 1),
(2, 4, 0, 1),
(3, 23, 0, 1),
(2, 351, 0, 1),
(3, 220, 0, 1),
(4, 394, 0, 1),
(5, 333, 0, 1),
(3, 195, 0, 1),
(1, 299, 0, 1),
(2, 9, 0, 1),
(3, 286, 0, 1),
(5, 110, 0, 1),
(2, 400, 0, 1),
(1, 263, 0, 1),
(4, 31, 0, 1),
(2, 394, 0, 1),
(1, 111, 0, 1),
(6, 80, 0, 1),
(3, 127, 0, 1),
(4, 86, 0, 1),
(5, 95, 0, 1),
(5, 3, 0, 1),
(4, 192, 0, 1),
(3, 380, 0, 1),
(2, 61, 0, 1),
(2, 279, 0, 1),
(2, 24, 0, 1),
(2, 325, 0, 1),
(3, 230, 0, 1),
(1, 172, 0, 1),
(5, 348, 0, 1),
(1, 211, 0, 1),
(5, 373, 0, 1),
(4, 200, 0, 1),
(5, 34, 0, 1),
(6, 184, 0, 1),
(6, 368, 0, 1),
(2, 80, 0, 1),
(1, 196, 0, 1),
(5, 247, 0, 1),
(2, 221, 0, 1),
(1, 132, 0, 1),
(3, 129, 0, 1),
(6, 277, 0, 1),
(1, 280, 0, 1),
(6, 336, 0, 1),
(6, 301, 0, 1),
(5, 73, 0, 1),
(3, 168, 0, 1),
(4, 6, 0, 1),
(6, 291, 0, 1),
(6, 94, 0, 1),
(2, 291, 0, 1),
(3, 390, 0, 1),
(5, 212, 0, 1),
(6, 128, 0, 1),
(1, 110, 0, 1),
(6, 330, 0, 1),
(4, 221, 0, 1),
(4, 255, 0, 1),
(2, 37, 0, 1),
(2, 347, 0, 1),
(1, 278, 0, 1),
(3, 65, 0, 1),
(2, 86, 0, 1),
(1, 387, 0, 1),
(3, 92, 0, 1),
(5, 97, 0, 1),
(4, 73, 0, 1),
(6, 2, 0, 1),
(1, 253, 0, 1),
(6, 269, 0, 1),
(2, 69, 0, 1),
(6, 250, 0, 1),
(1, 89, 0, 1),
(5, 231, 0, 1),
(6, 359, 0, 1),
(2, 55, 0, 1),
(4, 169, 0, 1),
(2, 66, 0, 1),
(1, 277, 0, 1),
(6, 395, 0, 1),
(5, 168, 0, 1),
(1, 214, 0, 1),
(2, 238, 0, 1),
(2, 101, 0, 1),
(3, 28, 0, 1),
(3, 296, 0, 1),
(1, 227, 0, 1),
(6, 235, 0, 1),
(4, 213, 0, 1),
(1, 391, 0, 1),
(4, 51, 0, 1),
(3, 206, 0, 1),
(3, 270, 0, 1),
(3, 8, 0, 1),
(1, 353, 0, 1),
(5, 158, 0, 1),
(3, 72, 0, 1),
(4, 324, 0, 1),
(6, 83, 0, 1),
(4, 205, 0, 1),
(6, 159, 0, 1),
(3, 193, 0, 1),
(3, 367, 0, 1),
(3, 323, 0, 1),
(4, 307, 0, 1),
(2, 87, 0, 1),
(6, 188, 0, 1),
(4, 60, 0, 1),
(5, 106, 0, 1),
(5, 36, 0, 1),
(3, 359, 0, 1),
(1, 18, 0, 1),
(1, 338, 0, 1),
(3, 386, 0, 1),
(5, 255, 0, 1),
(3, 216, 0, 1),
(4, 297, 0, 1),
(5, 40, 0, 1),
(6, 267, 0, 1),
(1, 243, 0, 1),
(6, 44, 0, 1),
(4, 188, 0, 1),
(3, 295, 0, 1),
(4, 97, 0, 1),
(2, 176, 0, 1),
(4, 228, 0, 1),
(3, 152, 0, 1),
(4, 214, 0, 1),
(4, 15, 0, 1),
(1, 160, 0, 1),
(6, 318, 0, 1),
(5, 157, 0, 1),
(2, 216, 0, 1),
(3, 85, 0, 1),
(5, 339, 0, 1),
(4, 285, 0, 1),
(5, 376, 0, 1),
(1, 144, 0, 1),
(5, 26, 0, 1),
(1, 108, 0, 1),
(4, 170, 0, 1),
(3, 137, 0, 1),
(6, 219, 0, 1),
(2, 346, 0, 1),
(6, 199, 0, 1),
(1, 170, 0, 1),
(1, 36, 0, 1),
(5, 238, 0, 1),
(4, 293, 0, 1),
(1, 148, 0, 1),
(4, 208, 0, 1),
(4, 90, 0, 1),
(4, 133, 0, 1),
(4, 9, 0, 1),
(2, 266, 0, 1),
(3, 196, 0, 1),
(3, 294, 0, 1),
(3, 204, 0, 1),
(3, 136, 0, 1),
(6, 354, 0, 1),
(6, 242, 0, 1),
(1, 358, 0, 1),
(4, 32, 0, 1),
(1, 120, 0, 1),
(1, 368, 0, 1),
(4, 62, 0, 1),
(4, 164, 0, 1),
(4, 234, 0, 1),
(5, 6, 0, 1),
(5, 88, 0, 1),
(5, 87, 0, 1),
(1, 159, 0, 1),
(4, 150, 0, 1),
(3, 67, 0, 1),
(4, 219, 0, 1),
(2, 3, 0, 1),
(3, 364, 0, 1),
(2, 183, 0, 1),
(5, 129, 0, 1),
(3, 271, 0, 1),
(6, 272, 0, 1),
(5, 48, 0, 1),
(5, 135, 0, 1),
(6, 18, 0, 1),
(2, 234, 0, 1),
(6, 251, 0, 1),
(2, 361, 0, 1),
(6, 38, 0, 1),
(5, 259, 0, 1),
(1, 63, 0, 1),
(3, 100, 0, 1),
(1, 190, 0, 1),
(1, 161, 0, 1),
(6, 326, 0, 1),
(2, 385, 0, 1),
(5, 213, 0, 1),
(4, 63, 0, 1),
(3, 192, 0, 1),
(2, 196, 0, 1),
(2, 286, 0, 1),
(4, 87, 0, 1),
(6, 278, 0, 1),
(6, 87, 0, 1),
(3, 157, 0, 1),
(1, 84, 0, 1),
(2, 123, 0, 1),
(4, 113, 0, 1),
(2, 175, 0, 1),
(2, 47, 0, 1),
(6, 160, 0, 1),
(3, 101, 0, 1),
(2, 139, 0, 1),
(5, 44, 0, 1),
(5, 321, 0, 1),
(3, 139, 0, 1),
(5, 330, 0, 1),
(4, 56, 0, 1),
(3, 291, 0, 1),
(4, 244, 0, 1),
(1, 142, 0, 1),
(6, 288, 0, 1),
(2, 40, 0, 1),
(2, 305, 0, 1),
(4, 138, 0, 1),
(5, 205, 0, 1),
(5, 86, 0, 1),
(4, 378, 0, 1),
(1, 149, 0, 1),
(6, 4, 0, 1),
(3, 395, 0, 1),
(4, 130, 0, 1),
(3, 324, 0, 1),
(6, 133, 0, 1),
(5, 13, 0, 1),
(2, 165, 0, 1),
(3, 326, 0, 1),
(3, 397, 0, 1),
(1, 78, 0, 1),
(4, 116, 0, 1),
(3, 344, 0, 1),
(5, 388, 0, 1),
(2, 372, 0, 1),
(4, 173, 0, 1),
(2, 344, 0, 1),
(5, 33, 0, 1),
(1, 169, 0, 1),
(2, 257, 0, 1),
(3, 13, 0, 1),
(5, 25, 0, 1),
(2, 48, 0, 1),
(4, 45, 0, 1),
(6, 180, 0, 1),
(6, 29, 0, 1),
(5, 124, 0, 1),
(3, 316, 0, 1),
(2, 245, 0, 1),
(3, 130, 0, 1),
(4, 281, 0, 1),
(2, 329, 0, 1),
(1, 168, 0, 1),
(5, 372, 0, 1),
(1, 229, 0, 1),
(4, 8, 0, 1),
(2, 324, 0, 1),
(6, 343, 0, 1),
(2, 189, 0, 1),
(2, 289, 0, 1),
(3, 119, 0, 1),
(3, 227, 0, 1),
(5, 223, 0, 1),
(4, 126, 0, 1),
(4, 174, 0, 1),
(5, 201, 0, 1),
(2, 163, 0, 1),
(5, 184, 0, 1),
(5, 179, 0, 1),
(6, 344, 0, 1);
