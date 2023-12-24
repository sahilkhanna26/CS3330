register pP {
    # our own internal register. P_pc is its output, p_pc is its input.
        pc:64 = 0; # 64-bits wide; 0 is its default value.

        # we could add other registers to the P register bank
        # register bank should be a lower-case letter and an upper-case letter, in that order.

        # there are also two other signals we can optionally use:
        # "bubble_P = true" resets every register in P to its default value
        # "stall_P = true" causes P_pc not to change, ignoring p_pc's value
}

 register cC {
     SF:1 = 0;
     ZF:1 = 1;
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
wire valB: 64;
wire valE: 64;



wire ifun: 4;

wire conditionsMet:1; 

ifun = opcode[0..4];

rA = i10bytes[12..16];

rB = i10bytes[8..12];


valC= [
   icode in { JXX } : i10bytes[8..72];
   icode in { CALL } : i10bytes[8..72];
   icode == IRMOVQ :i10bytes[16..80];
   icode == RMMOVQ :i10bytes[16..80];
   icode == MRMOVQ :i10bytes[16..80];

    1 : 0;

];

reg_srcA= [
    icode== OPQ: rA;
    icode== RMMOVQ: rA;
    icode== RRMOVQ: rA;
    icode== PUSHQ: rA; 
    icode== POPQ: REG_RSP;
    icode == RET: REG_RSP;

    1: REG_NONE;
];

reg_srcB= [
    icode == PUSHQ: REG_RSP;
    icode== POPQ: REG_RSP;
    icode== CALL: REG_RSP;
    icode == RET: REG_RSP;
    icode == OPQ: rB;
    icode == RMMOVQ: rB;
    icode == MRMOVQ: rB;
    1: REG_NONE;
];

valA = reg_outputA;
valB = reg_outputB;

conditionsMet = [
    ifun == ALWAYS : true;
    ifun == LE : C_SF || C_ZF;
    ifun == LT : C_SF;
    ifun == EQ : C_ZF;
    ifun == NE : !C_ZF;
    ifun == GE : !C_SF; 
    ifun == GT : !C_SF && !C_ZF;
    1 : false;
];

reg_inputE= [
    icode == IRMOVQ :valC;
    icode == RRMOVQ && conditionsMet:valA;
    icode == OPQ : valE;
    icode == PUSHQ: valE;
    icode == POPQ:valE;
    icode == CALL: valE;
    icode == RET: valE;
    1: 0xBAD;
];

reg_inputM= [
    icode == POPQ: mem_output;
    icode == MRMOVQ: mem_output;
    1:0xBAD;
];



reg_dstE= [
    !conditionsMet && icode == CMOVXX : REG_NONE;
    icode == IRMOVQ: rB;
    icode == RRMOVQ: rB;
    icode == MRMOVQ: rA;
    icode == OPQ: rB;
    icode == PUSHQ: REG_RSP;
    icode == POPQ: REG_RSP;
    icode == CALL: REG_RSP;
    icode == RET: REG_RSP;
    1: REG_NONE;
];

reg_dstM=[
    icode == POPQ: rA;
    icode == MRMOVQ: rA;
    1:REG_NONE;
];


mem_readbit= [
    icode == RMMOVQ : 0;
    icode == MRMOVQ : 1; 
    icode == POPQ: 1;
    icode == CALL: 0;
    icode == PUSHQ: 0;
    icode == RET: 1;
    1:0;
    ];

mem_writebit= [
    icode == RMMOVQ : icode in {RMMOVQ};
    icode == MRMOVQ : 0;
    icode == POPQ: 0;
    icode == CALL: 1;
    icode == PUSHQ: 1;
    icode == RET: 0;
    1: 0;

];


mem_input= [
    icode == CALL: P_pc+9;
    icode == RMMOVQ:reg_outputA;
    icode == PUSHQ:reg_outputA;

    1:0xBAD;
];
mem_addr= [
    icode== POPQ: reg_outputA; 
    icode == RET: reg_outputA;
    icode == CALL: valE;
    icode == PUSHQ: valE;
    icode == MRMOVQ: valE;
    icode == RMMOVQ: valE;
    1:0xBAD;
    ];

valE = [
    icode == RMMOVQ: valB + valC; 
    icode == MRMOVQ: valA + valC;
    icode == OPQ && ifun == ADDQ: reg_outputA + reg_outputB;
    icode == OPQ && ifun == SUBQ: reg_outputB - reg_outputA;
    icode == OPQ && ifun == ANDQ: reg_outputA & reg_outputB;
    icode == OPQ && ifun == XORQ: reg_outputA ^ reg_outputB; 
    icode == PUSHQ: reg_outputB - 8;
    icode == CALL: reg_outputB - 8;
    icode == POPQ: reg_outputB + 8;
    icode == RET: reg_outputB + 8;
    1:0;
];

 c_ZF = (valE == 0);
 c_SF = (valE >= 0x8000000000000000);

 stall_C = (icode != OPQ);


Stat = [
        icode == HALT : STAT_HLT;
        icode == CALL : STAT_AOK;
        icode == RET : STAT_AOK;
        icode == MRMOVQ : STAT_AOK;
        icode == IRMOVQ : STAT_AOK;
        icode == JXX: STAT_AOK;
        icode == RRMOVQ : STAT_AOK;
        icode == RMMOVQ: STAT_AOK;
        icode == NOP : STAT_AOK;
        icode == OPQ : STAT_AOK;
        icode == PUSHQ : STAT_AOK;
        icode == POPQ : STAT_AOK;

        icode >= TOO_BIG: STAT_INS;
        1          : STAT_INS;
];

p_pc = [
     icode == NOP: P_pc+1;
     icode == RRMOVQ: P_pc+2;
     icode == IRMOVQ: P_pc+10;
     icode == RMMOVQ: P_pc+10;
     icode == MRMOVQ: P_pc+10;
     icode == OPQ: P_pc+2;
     icode == JXX && conditionsMet: valC;
     icode == JXX && !conditionsMet: P_pc+9;
     icode == CALL: valC;
     icode == RET: mem_output;
     icode == PUSHQ:P_pc+2;
     icode == CMOVXX:P_pc+2;
     icode == POPQ: P_pc+2;
     1: P_pc+10;
]; # you may use math ops directly...