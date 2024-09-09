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

    if (new.role is distinct from old.role) then
        insert into user_history(user_id, date_of_change, description)
        values (new.user_id, current_timestamp, 'role changed from' || old.role || ' to ' || new.role);
    end if;

    return new;
end;
$$ language plpgsql;
create or replace trigger user_log_after_update_trigger
after update on users
for each row
execute function user_log_after_update();

create or replace function new_problem_added()
returns trigger as $$
begin
    insert into problem_history(problem_id, date_of_change, description)
    values (new.problem_id, current_timestamp, 'problem created with id = ' || new.problem_id);
    return new;
end;
$$ language plpgsql;
create or replace trigger new_problem_added_trigger
after insert on problems
for each row
execute function new_problem_added();

create or replace function problem_updated()
returns trigger as $$
begin
    if (new.statement is distinct from old.statement) then
        insert into problem_history(problem_id, date_of_change, description)
        values (new.problem_id, current_timestamp, 'problem statement changed from "' || old.statement || '" to "' || new.statement || '"');
    end if;

    if (new.statement is distinct from old.statement) then
        insert into problem_history(problem_id, date_of_change, description)
        values (new.problem_id, current_timestamp, 'problem answer changed from "' || old.answer || '" to "' || new.answer || '"');
    end if;
    return new;
end;
$$ language plpgsql;
create or replace trigger problem_updated_trigger
after update on problems
for each row
execute function problem_updated();

create or replace function announcement_created_log()
returns trigger as $$
begin
    insert into announcement_history(announcement_id, date_of_change, description)
    values (new.announcement_id, current_timestamp, 'new announcement created');
    return new;
end;
$$ language plpgsql;
create or replace trigger announcement_created_log_trigger
after insert on announcements
for each row
execute function announcement_created_log();

create or replace function announcement_update_log()
returns trigger as $$
begin
    if (new.title is distinct from old.title) then
        insert into announcement_history(announcement_id, date_of_change, description)
        values (new.announcement_id, current_timestamp, 'title updated');
    end if;

    if (new.content is distinct from old.content) then
        insert into announcement_history(announcement_id, date_of_change, description)
        values (new.announcement_id, current_timestamp, 'content changed');
    end if;

    return new;
end;
$$ language plpgsql;
create or replace trigger announcement_update_log_trigger
after update on announcements
for each row
execute function announcement_update_log();

create or replace function contest_announcement_created_log()
returns trigger as $$
begin
    insert into announcement_history(announcement_id, date_of_change, description)
    values (new.announcement_id, current_timestamp, 'this announcement appears in the contest');
    return new;
end;
$$ language plpgsql;
create or replace trigger contest_announcement_created_log_trigger
after insert on contest_announcements
for each row
execute function contest_announcement_created_log();