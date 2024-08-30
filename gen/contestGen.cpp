#include <vector>
#include <iostream>
#include <random>
#include <fstream>
using namespace std;
#define problems_cnt 8
struct Contest{
    static vector<int> get_problems(int n){
        int a[problems_cnt];
        for(int i=0;i<problems_cnt;i++)a[i]=i+1;
        random_shuffle(a,a+problems_cnt);
        vector<int> ans(n);
        for(int i=0;i<n;i++)ans[i]=a[i];
        return ans;
    }
    static void generate_contests(int contest_cnt){
        ofstream file("contestData");
        file << "copy contests FROM stdin with(format csv);\n";
        for(int i=0;i<contest_cnt;i++){
            file<<i+1<<",div"<<i<<",\'2024-09-01 "<<i*2+10<<":00:00\',"
                <<"2024-09-01 "<<i*2+11<<":00:00\',Welcome!,true\n";
        }
        file << "\\.";
        file.close();
    }
    static void add_problems(int contest_cnt){
        ofstream file("contestProblems");
        file << "copy contest_problems FROM stdin with(format csv);\n";
        for(int i=0;i<contest_cnt;i++){
            vector<int> x = get_problems(5);
            for(int y : x){
                file << i+1<<','<<y<<'\n';
            }
        }
        file << "\\.";
        file.close();
    }
};
int main(){
    Contest::generate_contests(5);
    Contest::add_problems(5);
}