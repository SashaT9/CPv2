# CPv2
# Description
CPv2 is a programming competition platform that allows users to participate in contests, solve problems, and track their achievements. The platform is developed primarily using postgreSQL and FastAPI. The idea is it implement CRUD operations.
# Features
- User management and authentication
- Problem creation and management
- Contest creation and management
- Submission and ranking system
- Announcements and feedback system

**Note**: many features are available only if the user has an admin role.

# Installation
1. Clone the repository:
```shell
git clone https://github.com/SashaT9/CPv2.git
cd CPv2
```
2. Generate data:
```shell
./data_generator/gen_all.sh
```
3. Create a local database in postgreSQL
```sql
CREATE USER sashat9 PASSWORD ‘1234’;
CREATE DATABASE cpv2db OWNER sashat9;
\c cpv2db
```
Also, grant the user with all privileges. 
4. Paste the generated data to your database.
# Usage
**Running the application**
```python
uvicorn app.main:app --reload
```
**Setting the role for a certain user to admin**
```sql
UPDATE users SET role = 'admin' WHERE username = '<your_username>';
```
