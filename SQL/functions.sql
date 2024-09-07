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

