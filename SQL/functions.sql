create or replace function log_user_settings_changes()
returns trigger as $$
begin
    if (new.username is distinct from old.username) then
        insert into user_settings_logs(user_id, date_of_change, description)
        values (old.user_id, current_timestamp, 'Username changed from ' || OLD.username || ' to ' || NEW.username);
    end if;

    if (new.password is distinct from old.password) then
        insert into user_settings_logs(user_id, date_of_change, description)
        values (old.user_id, current_timestamp, 'Password changed');
    end if;

    if (new.email is distinct from old.email) then
        insert into user_settings_logs(user_id, date_of_change, description)
        values (old.user_id, current_timestamp, 'Email changed from ' || OLD.email || ' to ' || NEW.email);
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger user_settings_trigger
after update on users
for each row
execute function log_user_settings_changes();