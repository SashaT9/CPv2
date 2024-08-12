document.getElementById('login').addEventListener('submit', async function (e) {
    e.preventDefault();

    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;

    const response = await fetch('http://127.0.0.1:8000/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password }),
    });

    if (response.ok) {
        const data = await response.json();
        const role = data.role;

        document.getElementById('login-form').style.display = 'none';

        if (role === 'admin') {
            document.getElementById('admin-section').style.display = 'block';
        } else {
            document.getElementById('user-section').style.display = 'block';
        }
    } else {
        alert('Login failed. Please check your credentials.');
    }
});
