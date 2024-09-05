#include <bits/stdc++.h>

using namespace std;

mt19937 rng(chrono::steady_clock::now().time_since_epoch().count());

int rd(int l, int r) {
	return uniform_int_distribution<int>(l, r)(rng);
}

const int Users = 400, Contests = 6;
struct ContestParticipants {
	int contest_id;
	int user_id;
	int score;
	int rank;
	ContestParticipants() {
		score = 0;
		rank = 1;
	}
};

string convert(string s) {
	return "\'" + s + "\'";
}
void genData_contest_participants(int num) {
	cout << "insert into contest_participants(contest_id, user_id, score, rank) values\n";
	map<int, set<int>> used;
	for (int i = 1; i <= num; i++) {
		ContestParticipants tmp;
		tmp.contest_id = rd(1, Contests);
		tmp.user_id = rd(1, Users);
		if (used[tmp.contest_id].contains(tmp.user_id))
			continue;

		used[tmp.contest_id].insert(tmp.user_id);
		cout << "(";
		cout << tmp.contest_id << ", ";
		cout << tmp.user_id << ", ";
		cout << tmp.score << ", ";
		cout << tmp.rank;
		cout << ")";
		cout << ",;"[i == num];
		cout << "\n";
	}
}
int main() {
	genData_contest_participants(1000);
}