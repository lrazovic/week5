pragma circom 2.0.3;
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "./hasher.circom";

// From https://docs.circom.io/more-circuits/more-basic-circuits/#extending-our-multiplier-to-n-inputs
template Multiplier2(){
   signal input in1;
   signal input in2;
   signal output out;

    out <== in1 * in2;
}

template MultiplierN(N){
   signal input in [N];
   signal output out;
   component comp[N - 1];

    for (var i = 0; i < N - 1; i++) {
        comp[i] = Multiplier2();
    }
    comp[0].in1 <== in [0];
    comp[0].in2 <== in [1];
    for (var i = 0; i < N - 2; i++) {
        comp[i + 1].in1 <== comp[i].out;
        comp[i + 1].in2 <== in [i + 2];

    }

    out <== comp[N - 2].out;
}

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template DualMux() {
    signal input in [2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0;
    out[0] <== (in [1] - in [0]) * s + in [0];
    out[1] <== (in [0] - in [1]) * s + in [1];
}

// Verifies that merkle proof is correct for given merkle root and a leaf
// pathIndices input is an array of 0/1 selectors telling whether given pathElement is on the left or right side of merkle path
template ManyMerkleTreeChecker(levels, length, nInputs) {
    signal input leaf[nInputs];
    signal input pathElements[levels];
    signal input pathIndices[levels];
    signal input roots[length];
    signal output out;

    component selectors[levels];
    component hashers[levels];

    component leaf_hasher = Poseidon(nInputs);
    for (var i = 0; i < nInputs; i++) {
        log(leaf[i]);
        leaf_hasher.inputs[i] <== leaf[i];
    }

    for (var i = 0; i < levels; i++) {
        selectors[i] = DualMux();
        selectors[i].in[0] <== i == 0 ? leaf_hasher.out : hashers[i - 1].hash;
        selectors[i].in[1] <== pathElements[i];
        selectors[i].s <== pathIndices[i];

        hashers[i] = HashLeftRight();
        hashers[i].left <== selectors[i].out[0];
        hashers[i].right <== selectors[i].out[1];
    }

    // [assignment] verify that the resultant hash (computed merkle root)
    // is in the set of roots received as input
    // Note that running test.sh should create a valid proof in current circuit, even though it doesn't do anything.
    component multiplier = MultiplierN(levels);
    for (var index = 0; index < length; index++) {
        log(hashers[levels - 1].hash - roots[index]);
        multiplier.in[index] <== hashers[levels - 1].hash - roots[index];
    }
    multiplier.out === 0;
}

component main = ManyMerkleTreeChecker(2, 2, 3);
