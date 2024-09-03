#include <bits/stdc++.h>

using namespace std;

mt19937 rng(chrono::steady_clock::now().time_since_epoch().count());

int rd(int l, int r) {
	return uniform_int_distribution<int>(l, r)(rng);
}

struct Announcement {
	string title;
	string content;
	string date;
};

string convert(string s) {
	return "\'" + s + "\'";
}
void genData_weekend_contests(int num) {
	cout << "insert into announcements(title, content, date_posted) values\n";
	for (int i = 1; i <= num; i++) {
		Announcement tmp;
		tmp.title = "We would like to invite you to another Weekend Practice Contest #" + to_string(i);
		tmp.content = "You will be given a 5-10 problems to solve in 2-4 hours.\nRanking for the contest will be distributed after the ending.\nEveryone can participate. \nGood luck.";
		int cnt = 14 * (num - i + 1);
		tmp.date = "\'2024-09-01 16:35:00\'::timestamp - interval \'" + to_string(cnt) + " days\'";
		cout << "(";
		cout << convert(tmp.title) << ", ";
		cout << convert(tmp.content) << ", ";
		cout << tmp.date;
		cout << ")";
		cout << ",;"[i == num];
		cout << "\n";
	}
}
int main() {
	genData_weekend_contests(6);
}