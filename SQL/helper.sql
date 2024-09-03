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
end;
$$ language plpgsql;