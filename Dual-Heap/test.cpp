#include <iostream>
#include "../../ad1/impl/integers.h"
using namespace std;

int main() {
    W_m w1 = {255};
    W_m w2 = {4};
    W_mxm w3 = w1 * w2;
    cout << str(w1) << endl;
    cout << str(w2) << endl;
    cout << str(uhalf(w3)) << endl;
    cout << str(lhalf(w3)) << endl;
}
