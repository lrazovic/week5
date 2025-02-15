pragma circom 2.0.3;

include "iszero.circom";

template ForceEqualIfEnabled() {
    signal input enabled;
    signal input in [2];

    component isz = IsZero();

    in [1] - in [0] ==> isz.in;

    (1 - isz.out) * enabled === 0;
}

component main{ public[enabled, in] } = ForceEqualIfEnabled();
