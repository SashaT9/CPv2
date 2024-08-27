document.getElementById('register-form').addEventListener('submit', async function (event) {
    event.preventDefault();

    const username = document.getElementById('reg-username').value;
    const password = document.getElementById('reg-password').value;
    const isAdmin = document.getElementById('reg-admin').checked;

    const response = await fetch('/register', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password, is_admin: isAdmin }),
    });

    if (response.ok) {
        const data = await response.json();
        localStorage.setItem('token', data.access_token);
        showMessage("Registration successful!");
    } else {
        showMessage("Registration failed!");
    }
});

document.getElementById('login-form').addEventListener('submit', async function (event) {
    event.preventDefault();

    const username = document.getElementById('login-username').value;
    const password = document.getElementById('login-password').value;

    const response = await fetch('/token', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
            username: username,
            password: password,
        }),
    });

    if (response.ok) {
        const data = await response.json();
        localStorage.setItem('token', data.access_token);
        showMessage("Login successful!");
    } else {
        showMessage("Login failed!");
    }
});

function showMessage(message) {
    const messagesDiv = document.getElementById('messages');
    messagesDiv.innerHTML = <p>${message}</p>;
}