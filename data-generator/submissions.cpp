#include <bits/stdc++.h>

using namespace std;

mt19937 rng(chrono::steady_clock::now().time_since_epoch().count());

int rd(int l, int r) {
	return uniform_int_distribution<int>(l, r)(rng);
}

const int Users = 400, Problems = 14;
const int Submissions = 2 * Users * Problems;
struct Solution {
	string answer;
};

struct Submission {
	int user_id;
	int problem_id;
	int solution_id;
	string date_of_submission;
	string status;
};

string convert(string s) {
	return "\'" + s + "\'";
}
void genData_Solutions(int num) {
	vector<string> data = {"yes", "no"};
	for (int i = 0; i < 20; i++) {
		data.push_back(to_string(rd(1, 100)));
	}
	cout << "insert into solutions(answer) values\n";
	for (int i = 1; i <= num; i++) {
		Solution tmp;
		tmp.answer = data[rd(0, data.size() - 1)];
		cout << "(";
		cout << convert(tmp.answer);
		cout << ")";
		cout << ",;"[i == num];
		cout << "\n";
	}
}
void genData_Submissions(int num) {
	cout << "insert into submissions(user_id, problem_id, solution_id, date_of_submission, status) values\n";
	for (int i = 1; i <= num; i++) {
		Submission tmp;
		tmp.user_id = rd(1, Users);
		tmp.problem_id = rd(1, Problems);
		tmp.solution_id = i;
		tmp.date_of_submission = "'2024-06-01 00:00:00'::timestamp + random() * ('2024-09-07 00:00:00'::timestamp - '2024-06-01 00:00:00'::timestamp)";
		tmp.status = (rd(0, 4) == 0 ? "accepted" : "wrong answer");

		cout << "(";
		cout << tmp.user_id << ", ";
		cout << tmp.problem_id << ", ";
		cout << tmp.solution_id << ", ";
		cout << tmp.date_of_submission << ", ";
		cout << convert(tmp.status);
		cout << ")";
		cout << ",;"[i == num];
		cout << "\n";
	}
}
int main() {
	genData_Solutions(Submissions);
	genData_Submissions(Submissions);
}