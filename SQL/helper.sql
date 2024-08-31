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