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

create or replace function valid_email()
returns trigger as $$
begin
    if(not (new.email ~ '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$'))
        then return old;
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger valid_email_trigger
before insert or update on users
for each row
execute function valid_email();

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
