#include <bits/stdc++.h>

using namespace std;

mt19937 rng(chrono::steady_clock::now().time_since_epoch().count());

int rd(int l, int r) {
	return uniform_int_distribution<int>(l, r)(rng);
}

std::vector<std::string> adjectives = {
    "Quick", "Lazy", "Happy", "Sad", "Bright", "Dark", "Fierce", "Gentle", "Brave", "Clever",
    "Mighty", "Quiet", "Bold", "Sly", "Swift", "Calm", "Loyal", "Shy", "Wild", "Strong"
};

std::vector<std::string> nouns = {
    "Tiger", "Eagle", "Lion", "Wolf", "Bear", "Shark", "Falcon", "Fox", "Panda", "Otter",
    "Dragon", "Hawk", "Panther", "Leopard", "Cheetah", "Viper", "Cobra", "Jaguar", "Raven", "Badger"
};
struct User {
	string username;
	string password;
	string email;
	string role;
	void genUsername() {
		int n = adjectives.size(), m = nouns.size();
		username = adjectives[rd(0, n - 1)] + nouns[rd(0, m - 1)] + to_string(rd(1, 999));
	}
	void genPassword() {
		int length = rd(6, 12);
		for (int i = 0; i < length; i++) {
			if (rd(0, 1) == 1)
				password += char('a' + rd(0, 25));
			else
				password += char('0' + rd(0, 9));
		}
	}
	void genEmail() {
		vector<string> domens = {"@gmail.com", "@cpv2.com", "@smile.sad", "@akame.eris"};
		email = username + domens[rd(0, 3)];
	}
	void genRole() {
		role = "user";
	}
	User() {
		genUsername();
		genPassword();
		genEmail();
		genRole();
	}
};
string convert(string s) {
	return "\'" + s + "\'";
}
void genData(int num) {
	cout << "insert into users(username, password, email, role) values\n";
	for (int i = 0; i < num; i++) {
		User user = User();
		cout << "(";
		cout << convert(user.username) << ", ";
		cout << convert(user.password) << ", ";
		cout << convert(user.email) << ", ";
		cout << convert(user.role);
		cout << ")";
		cout << ",;"[i + 1 == num];
		cout << "\n";
	}
}
int main() {
	genData(400);
}