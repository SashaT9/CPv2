# CPv2
Welcome to CPv2 what is a CRUD simulator of a competitive programming website(not really).
# Features
- sign up / login;
- view your achievements;
- create/read/update/delete announcements;
- create/read/update/delete problems;
- handle contests in real time.


Please note that not all actions are available for a specific user, but only for the admin.

To grant your user with an admin role use the following command:
```
update users set role = 'admin' where username = '<your_username>'
```