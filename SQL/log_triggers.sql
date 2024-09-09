create or replace function user_log_after_insert()
returns trigger as $$
begin
    insert into user_history(user_id, date_of_change, description)
    values (new.user_id, current_timestamp, 'new user created. Username: ' || new.username);
    return new;
end;
$$ language plpgsql;
create or replace trigger user_log_after_insert_trigger
after insert on users
for each row
execute function user_log_after_insert();

create or replace function user_log_after_update()
returns trigger as $$
begin
    if (new.username is distinct from old.username) then
        insert into user_history(user_id, date_of_change, description)
        values (new.user_id, current_timestamp, 'username changed from ' || old.username || ' to ' || new.username);
    end if;

    if (new.email is distinct from old.email) then
        insert into user_history(user_id, date_of_change, description)
        values (new.user_id, current_timestamp, 'email changed from ' || old.email || ' to ' || new.email);
    end if;

    if (new.password is distinct from old.password) then
        insert into user_history(user_id, date_of_change, description)
        values (new.user_id, current_timestamp, 'password changed from ' || old.password || ' to ' || new.password);
    end if;

    return new;
end;
$$ language plpgsql;
create or replace trigger user_log_after_update_trigger
after update on users
for each row
execute function user_log_after_update();
