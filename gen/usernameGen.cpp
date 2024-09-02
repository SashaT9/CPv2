#include <random>
#include <fstream>
#include <iostream>
using namespace std;
string nounFilename = "nouns.txt";
string adjFilename = "adjectives.txt";
string outputDataFilename = "usernameData";
struct Users{
    static string generate_rnd_str(int length){
        string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()";
        string res;
        for (int i = 0; i < length; ++i)
            res += chars[random() % chars.length()];
        return res;
    }
    static string generate_rnd_charnumb_str(int length){
        string chars = "abcdefghijklmnopqrstuvwxyz0123456789";
        string res;
        for (int i = 0; i < length; ++i)
            res += chars[random() % chars.length()];
        return res;
    }
    static string generate_pass() {
        int length = int(random()%8)+8;
        return generate_rnd_str(length);
    }
    static string generate_username(){
        int noun = int(random()%68)+1;
        int adj = int(random()%69)+1;
        ifstream file1(nounFilename);
        ifstream file2(adjFilename);
        if (!file1) {
            cout << "File not found:" << nounFilename << endl;
            throw exception();
        }
        if (!file2) {
            cout << "File not found:" << adjFilename << endl;
            throw exception();
        }
        string noun_str,adj_str;
        int cnt = 1;
        while (getline(file1, noun_str)) {
            if (cnt == noun) {
                file1.close();cnt=1;break;
            }
            cnt++;
        }
        while (getline(file2, adj_str)) {
            if (cnt == adj) {
                file2.close();cnt = 1;break;
            }
            cnt++;
        }
        return adj_str+noun_str;
    }
    static string generate_email() {
        std::string domains[] = {"gmail.com", "gmail.com", "yahoo.com",
                                 "outlook.com", "hotmail.com"};
        return generate_rnd_charnumb_str(8) + "@" + domains[random() % 4];
    }
    static void generate_users(int n){
        ofstream file(outputDataFilename);
        file << "copy users(user_id,username,password,email,role) FROM stdin with(format csv);\n";
        for(int i=0;i<n;i++){
            file << i << ',' << generate_username() << ',' << generate_pass() << ','
                << generate_email() << ",user\n";
        }
        file << "\\.";
    }
};
int main(){
    Users::generate_users(200);
}