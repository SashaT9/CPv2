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

create or replace function update_user_ratings(mcontest_id int)
returns void as $$
declare
    avg_rating float;
    delta int := 20;
begin

    if not exists (select * from contests where contest_id = mcontest_id) then
        raise notice 'Contest ID % does not exist', mcontest_id;
        return;
    end if;

    select avg(rating) into avg_rating
    from user_achievements join contest_participants using(user_id)
    where contest_id = mcontest_id;


    update user_achievements
    set rating = rating + delta * (
        (select score from contest_participants where contest_id = mcontest_id and contest_participants.user_id = user_achievements.user_id) /
        greatest(1.0, (select avg(score) from contest_participants where contest_id = mcontest_id)) - rating / greatest(1.0, avg_rating)
    )
    where exists (
        select * from contest_participants
        where contest_id = mcontest_id and contest_participants.user_id = user_achievements.user_id
    );

exception
    when others then
        raise notice 'An error occurred: %', SQLERRM;
end;
$$ language plpgsql;