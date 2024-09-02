CREATE OR REPLACE FUNCTION log_user_settings_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Username change
    IF (NEW.username IS DISTINCT FROM OLD.username) THEN
        INSERT INTO user_settings_logs(user_id, date_of_change, description)
        VALUES (OLD.user_id, CURRENT_TIMESTAMP, 'Username changed from ' || OLD.username || ' to ' || NEW.username);
    END IF;

    -- Password change
    IF (NEW.password IS DISTINCT FROM OLD.password) THEN
        INSERT INTO user_settings_logs(user_id, date_of_change, description)
        VALUES (OLD.user_id, CURRENT_TIMESTAMP, 'Password changed');
    END IF;

    -- Email change
    IF (NEW.email IS DISTINCT FROM OLD.email) THEN
        INSERT INTO user_settings_logs(user_id, date_of_change, description)
        VALUES (OLD.user_id, CURRENT_TIMESTAMP, 'Email changed from ' || OLD.email || ' to ' || NEW.email);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER user_settings_trigger
AFTER UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION log_user_settings_changes();

create or replace function valid_password()
    -- additional validations "no 4 same symbols in a raw"? (more complex trigger -> more points)
returns trigger as $$
begin
    if( length(new.password)<8)
        -- thow exception?
        then return old;
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger valid_password_trigger
before insert or update on users
execute function valid_password();

create or replace function valid_email()
returns trigger as $$
begin
    if(not (new.emai ~ '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'))
        then return old;
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger valid_email_trigger
before insert or update on users
execute function valid_email();

create or replace function valid_status()
returns trigger as $$
begin
    if(new.status = any('accepted','testing','wrong answer','rejected','internal error'))
        then return old;
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger valid_status_trigger
before insert or update on submissions
execute function valid_status();

create or replace function valid_start_time()
returns trigger as $$
begin
    if(now()<new.start_time or now()-new.start_time<'15 minutes')
        then return old;
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger valid_start_time_trigger
before insert on contests
execute function valid_start_time();

create or replace function past_contests_timechange()
returns trigger as $$
begin
    if(new.start_time<now() or (new.start_time<old.start_time and now()-new.start_time < '60 minutes'))
       then return old;
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger past_contests_timechange_trigger
before update on contests
execute function past_contests_timechange();

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
for each row execute function update_achievements();


create trigger solution_update_trigger
before update of answer on problems
execute function retest_problem();

create or replace function update_max_performance(c_id int)
returns void as $$
declare
    user_info record;
begin
    if (select end_time from contests where c_id=contests.contest_id) > now()
        then return;
    end if;
    for user_info in (select * from contest_participants where contest_id = c_id) loop
        update user_achievements
        set max_performance = max(max_performance,user_info.score)
        where user_id = user_info.user_id;
    end loop;
end;
$$ language plpgsql;