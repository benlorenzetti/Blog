#include <iostream>
#include "../../ad1/impl/integers.h"
using namespace std;

int main() {
    W_m w1 = {255};
    W_m w2 = {4};
    W_m w3 = w1 * w2;
    W_mxm w4(w1, w2);
    cout << str(w1) << endl;
    cout << str(w2) << endl;
    cout << str(w3) << endl;
    cout << str(upperhalf(w4)) << endl;
    cout << str(lowerhalf(w4)) << endl;
}
