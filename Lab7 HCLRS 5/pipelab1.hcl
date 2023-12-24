########## the PC and condition codes registers #############
register fF { pc:64 = 0; }
register dW {
	icode: 4 = NOP;
	valC: 64 = 0;
	dstE:4 = REG_NONE;
	Stat:3 = STAT_AOK;
	valA:64 = 0;
}
########## Fetch #############
pc = F_pc;
d_icode = i10bytes[4..8];

wire rA:4, rB:4;

d_Stat = [
	d_icode == HALT: STAT_HLT;
	d_icode == RRMOVQ: STAT_AOK;
	d_icode == IRMOVQ: STAT_AOK;
	1: STAT_INS;
];


rA =[
	d_icode == RRMOVQ : i10bytes[12..16];
	d_icode == IRMOVQ : i10bytes[12..16];
	1: REG_NONE;
];


rB =[
	d_icode == RRMOVQ : i10bytes[8..12];
	d_icode == IRMOVQ : i10bytes[8..12];
	1: REG_NONE;
];


d_valC = [
	d_icode == RRMOVQ : i10bytes[16..80];
	d_icode == IRMOVQ : i10bytes[16..80];
	1:0;
];

f_pc = [
    d_icode == NOP: F_pc+1;
    d_icode == HALT: F_pc+1;
    d_icode == RET: F_pc+1;
    d_icode == NOP: F_pc+1;
    d_icode == RRMOVQ: F_pc+2;
    d_icode == OPQ: F_pc+2;
    d_icode == PUSHQ: F_pc+2;
    d_icode == POPQ: F_pc+2;
    d_icode == JXX: F_pc+9;
    d_icode == CALL: F_pc+9;
    1: F_pc+10;
  ];

########## Decode #############

# source selection
reg_srcA = [
	d_icode in {RRMOVQ} : rA;
	1 : REG_NONE;
];

d_valA = [
	((reg_srcA == reg_dstE && reg_srcA != REG_NONE)): reg_inputE;
	1: reg_outputA;
];

d_dstE = [
	d_icode == IRMOVQ : rB;
	d_icode == RRMOVQ : rB;
	1:REG_NONE;
];


########## Execute #############



########## Memory #############




########## Writeback #############


# destination selection
reg_dstE = W_dstE;

reg_inputE = [ # unlike book, we handle the "forwarding" actions (something + 0) here
	W_icode == RRMOVQ : W_valA;
	W_icode == IRMOVQ : W_valC;
	1: 0xBADBADBAD
];


########## PC and Status updates #############

Stat = W_Stat;

