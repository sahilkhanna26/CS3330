register pP {
    # our own internal register. P_pc is its output, p_pc is its input.
        pc:64 = 0; # 64-bits wide; 0 is its default value.

        # we could add other registers to the P register bank
        # register bank should be a lower-case letter and an upper-case letter, in that order.

        # there are also two other signals we can optionally use:
        # "bubble_P = true" resets every register in P to its default value
        # "stall_P = true" causes P_pc not to change, ignoring p_pc's value
}

# "pc" is a pre-defined input to the instruction memory and is the
# address to fetch 10 bytes from (into pre-defined output "i10bytes").
pc = P_pc;

# we can define our own input/output "wires" of any number of 0<bits<=80
wire opcode:8, icode:4;

# the x[i..j] means "just the bits between i and j".  x[0..1] is the
# low-order bit, similar to what the c code "x&1" does; "x&7" is x[0..3]
opcode = i10bytes[0..8];   # first byte read from instruction memory
icode = opcode[4..8];      # top nibble of that byte

/* we could also have done i10bytes[4..8] directly, but I wanted to
 * demonstrate more bit slicing... and all 3 kinds of comments      */
// this is the third kind of comment

# named constants can help make code readable
const TOO_BIG = 0xC; # the first unused icode in Y86-64

# some named constants are built-in: the icodes, ifuns, STAT_??? and REG_???


# Stat is a built-in output; STAT_HLT means "stop", STAT_AOK means
# "continue".  The following uses the mux syntax described in the
# textbook

wire rB: 4, valC: 64;

wire rA: 4;

wire valA: 64;

rA = i10bytes[12..16];

rB = i10bytes[8..12];

valC= [
    icode == JXX:  i10bytes[8..72];
    icode == IRMOVQ: i10bytes[16..80];
    1:0xBAD;
];

reg_srcA= rA;

valA = reg_outputA;

reg_inputE= [
    icode == IRMOVQ :valC;
    icode == RRMOVQ :valA;
    1: 0xBAD;
];



reg_dstE= [
    icode == IRMOVQ: rB;
    icode == RRMOVQ: rB;
    1: REG_NONE;
];




Stat = [
        icode == HALT : STAT_HLT;
    #icode == JXX : STAT_INS;
        icode == CALL : STAT_INS;
        icode == RET: STAT_INS;
        icode >= TOO_BIG: STAT_INS;
        1             : STAT_AOK;
];

p_pc = [
     icode == HALT:  P_pc + 1;
     icode == NOP: P_pc+1;
     icode == RRMOVQ: P_pc+2;
     icode == IRMOVQ: P_pc+10;
     icode == RMMOVQ: P_pc+10;
     icode == MRMOVQ: P_pc+10;
     icode == OPQ: P_pc+2;
     icode == JXX: valC;
     icode == CALL: P_pc+8;
     icode == RET: P_pc+1;
     icode == PUSHQ:P_pc+2;
     icode == POPQ: P_pc+2;
     1: P_pc+10;
]; # you may use math ops directly...