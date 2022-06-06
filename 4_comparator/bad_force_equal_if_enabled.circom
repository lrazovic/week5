pragma circom 2.0.3;

template BadForceEqualIfEnabled() {
    signal input enabled;
    signal input in[2];
    
    // There are constraints depending on the value of the condition and it can be unknown during the constraint generation phase
    if (enabled) {
        in[1] === in[0];
    }
}

component main = BadForceEqualIfEnabled();