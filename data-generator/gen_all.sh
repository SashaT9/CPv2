#!/bin/bash

rm ./SQL/gen_all.sql

touch ./SQL/gen_all.sql

cat ./SQL/delete.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/create.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/helper.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/functions.sql >> ./SQL/gen_all.sql

echo  >> ./SQL/gen_all.sql
cat ./SQL/fill-tables/gen_users.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/fill-tables/gen_topics.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/fill-tables/gen_announcements.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/fill-tables/gen_problems.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/fill-tables/gen_submissions.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/fill-tables/gen_contests.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/fill-tables/gen_contest_announcements.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/fill-tables/gen_contest_problems.sql >> ./SQL/gen_all.sql
echo  >> ./SQL/gen_all.sql
cat ./SQL/fill-tables/gen_contest_participants.sql >> ./SQL/gen_all.sql