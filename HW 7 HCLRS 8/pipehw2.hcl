########## the PC and condition codes registers #############
register fF { predPC:64 = 0;}





########## Fetch #############


pc = [
	M_icode == JXX && !M_valid: M_valA;
	W_icode == RET: W_valM;
	1:F_predPC;
];
f_ifun = i10bytes[0..4];
f_icode = i10bytes[4..8];


f_Stat = [
	f_icode == HALT: STAT_HLT;
	f_icode == RRMOVQ: STAT_AOK;
	f_icode == IRMOVQ: STAT_AOK;
	f_icode == MRMOVQ: STAT_AOK;
	f_icode == RMMOVQ: STAT_AOK;
	f_icode == JXX : STAT_AOK;
	f_icode == PUSHQ: STAT_AOK;
	f_icode == POPQ: STAT_AOK;
	f_icode == OPQ: STAT_AOK;
	f_icode == CALL: STAT_AOK;
	f_icode == CMOVXX: STAT_AOK;
	f_icode == RET: STAT_AOK;
	f_icode == NOP: STAT_AOK;
	f_icode > 0xb : STAT_INS;
	1: STAT_INS;
];


wire rA:4, rB:4;
wire conditionsMet:1; 




rA =i10bytes[12..16];
f_rA = rA;

rB = i10bytes[8..12];
f_rB = rB;


f_valC = [
	f_icode == RRMOVQ : i10bytes[16..80];
	f_icode == IRMOVQ : i10bytes[16..80];
	f_icode == RMMOVQ : i10bytes[16..80];
	f_icode == MRMOVQ : i10bytes[16..80];
	f_icode == JXX  : i10bytes[8..72];
	f_icode == CALL : i10bytes[8..72];
	1:0;
];

f_predPC = [
	f_icode == JXX : f_valC;
	f_icode == CALL : f_valC;
	1:f_valP
	];

  f_valP = [
    f_icode == RET: pc +1;
    f_icode == RRMOVQ: pc+2;
    f_icode == OPQ: pc+2;
    f_icode == PUSHQ: pc+2;
    f_icode == POPQ: pc+2;
    f_icode == JXX: pc+9;
    f_icode == IRMOVQ :pc+10;
    f_icode == RMMOVQ :pc+10;
    f_icode == MRMOVQ: pc+10;
	f_icode == CALL: pc+9;
	f_icode == CMOVXX: pc+2;
 	1:pc+1;
  ];

########## Decode #############
register fD{
	icode: 4 = NOP;
	valC: 64 = 0;
	ifun:4 = 0;
	Stat:3 = STAT_BUB;
	rA:4 = REG_NONE;
    rB:4 = REG_NONE;
    valP:64 = 0;
}

d_icode = D_icode;
d_valC = D_valC;
d_ifun = D_ifun;
d_Stat = D_Stat;


# source selection
reg_srcA = [
	d_icode == PUSHQ: D_rA;
	d_icode== OPQ: D_rA;
	d_icode== RRMOVQ: D_rA;
	d_icode == CMOVXX: D_rA;
	d_icode == RMMOVQ: D_rA;
	d_icode == POPQ: REG_RSP;
	d_icode == RET: REG_RSP;
	1 : REG_NONE;
];

d_srcA = reg_srcA;


reg_srcB = [
	d_icode == PUSHQ: REG_RSP;
	d_icode == OPQ: D_rB;
	d_icode == RMMOVQ: D_rB;
	d_icode == MRMOVQ: D_rB;
	d_icode == POPQ: REG_RSP;
	d_icode == RET: REG_RSP;
	d_icode == CALL: REG_RSP;
	1 : REG_NONE;
];

d_srcB = reg_srcB;

d_dstM = [
	d_icode ==  MRMOVQ  : D_rA;
	d_icode == POPQ: D_rA;
	1 : REG_NONE;
];




d_valA = [
	d_icode == CALL: D_valP;
	d_icode == JXX: D_valP;  
	reg_srcA == REG_NONE: 0;
	reg_srcA == e_dstE:e_valE;
	reg_srcA == m_dstM: m_valM;
	reg_srcA == W_dstM: W_valM; 
	reg_srcA == m_dstE: m_valE;
	reg_srcA == reg_dstE: reg_inputE;
	
	1: reg_outputA;
];
d_valB = [
	reg_srcB == REG_NONE: 0;
	reg_srcB == e_dstE:e_valE;
	reg_srcB == m_dstM: m_valM;
	reg_srcB == W_dstM: W_valM; 
	reg_srcB == m_dstE: m_valE;
	reg_srcB == reg_dstE: reg_inputE;
	
	1: reg_outputB;
];

d_dstE = [
	d_icode == RRMOVQ : D_rB;
	d_icode == IRMOVQ : D_rB;
	d_icode == CMOVXX: D_rB;
	d_icode == OPQ : D_rB;
	d_icode == PUSHQ: REG_RSP;
	d_icode == POPQ: REG_RSP;
	d_icode == CALL: REG_RSP;
	d_icode == RET: REG_RSP;
	1:REG_NONE;
];





########## Execute #############

register dE{
	icode: 4 = NOP;
	ifun:4 = 0;
	valC: 64 = 0;
	dstE:4 = REG_NONE;
	Stat:3 = STAT_BUB;
	valA:64 = 0;
	valB: 64 = 0;
	srcA:4 = REG_NONE;
	srcB:4 = REG_NONE;
	dstM:4 = REG_NONE;
}


register cC {
     SF:1 = 0;
     ZF:1 = 1;
 }


 c_ZF = (e_valE == 0);
 c_SF = (e_valE >= 0x8000000000000000);

 stall_C = (e_icode != OPQ);

conditionsMet = [
    E_ifun == 0 : true;
    E_ifun == LE : C_SF || C_ZF;
    E_ifun == LT : C_SF;
    E_ifun == EQ : C_ZF;
    E_ifun == NE : !C_ZF;
    E_ifun == GE : !C_SF; 
    E_ifun == GT : !C_SF && !C_ZF;
    1 : false;
];

e_valid = conditionsMet;
e_icode = E_icode;
e_Stat = E_Stat;
e_valC = E_valC;
e_valA = E_valA;
e_valB = E_valB;
e_dstM = E_dstM;

e_valE = [
	e_icode == RRMOVQ : e_valA;
	e_icode == IRMOVQ : e_valC;
	e_icode == RMMOVQ : e_valC + e_valB;
	e_icode == MRMOVQ : e_valC + e_valB;
	e_icode == OPQ && E_ifun == SUBQ : e_valB - e_valA;
	e_icode == OPQ && E_ifun == ADDQ : e_valA + e_valB;
	e_icode == OPQ && E_ifun == XORQ : e_valA ^ e_valB;
	e_icode == OPQ && E_ifun == ANDQ : e_valA & e_valB;
	e_icode == PUSHQ: e_valB - 8;
	e_icode == CALL: e_valB - 8;
	e_icode == RET: e_valB + 8;
	e_icode == POPQ: e_valB + 8;
	1 : 0;
];

e_dstE = [
	!conditionsMet && e_icode == CMOVXX : REG_NONE;
    e_icode == IRMOVQ: E_dstE;
    e_icode == RRMOVQ: E_dstE;
    e_icode == PUSHQ: REG_RSP;
    e_icode == POPQ: REG_RSP;
    e_icode == OPQ:  E_dstE;
    e_icode == CALL: REG_RSP;
    e_icode == RET: REG_RSP;
    1:REG_NONE;
];


########## Memory #############
register eM {
	icode: 4 = NOP;
	Stat:3 = STAT_AOK;
	valA:64 = 0;
	valB:64 = 0;
	valC:64 = 0;
	valE:64 = 0;
	valid:1 = 0;
	dstE:4 = REG_NONE;
	dstM:4 = REG_NONE;

}


mem_addr = [ # output to memory system
	M_icode in { RMMOVQ, MRMOVQ } : M_valE;
	M_icode == PUSHQ: M_valE;
	M_icode == POPQ:M_valA;
	M_icode == CALL: M_valE;
	M_icode == RET: M_valA;
	1 : 0; # Other instructions don't need address
];
mem_readbit =  [
	M_icode == MRMOVQ : 1;
	M_icode == PUSHQ: 0;
	M_icode == POPQ:1;
	M_icode == RET: 1;
	M_icode == CALL: 0;
	1:0;
	];
 # output to memory system
mem_writebit = [
	M_icode == RMMOVQ: M_icode in {RMMOVQ};
	M_icode == PUSHQ: 1;
	M_icode == MRMOVQ : 0;
	M_icode == POPQ : 0;
	M_icode == RET  : 0;
	M_icode == CALL: 1;

	1:0;
];
# output to memory system
mem_input = M_valA;#POSSIBLE ISSUE


m_valM = mem_output; # input from mem_readbit and mem_addr
m_dstM = M_dstM;
m_icode = M_icode;
m_Stat = M_Stat;
m_valC = M_valC;
m_dstE = M_dstE;
m_valB = M_valB;
m_valA = M_valA;
m_valE = M_valE;
########## Writeback #############

register mW {
	icode: 4 = NOP;
	Stat:3 = STAT_BUB;
	valB:64 = 0;
	valC:64 = 0;
	valE:64 = 0;
	valM:64 = 0;
	valA:64 = 0;
	dstE:4 = REG_NONE;
	dstM:4 = REG_NONE;

}

# destination selection
reg_dstE =W_dstE;


reg_inputE = [ # unlike book, we handle the "forwarding" actions (something + 0) here
	W_icode == POPQ: W_valE;
	W_icode == PUSHQ :W_valE;
	W_icode == RRMOVQ : W_valE;
	W_icode == IRMOVQ : W_valE;
	W_icode == OPQ : W_valE;
	W_icode == RET: W_valE;
	W_icode == CALL: W_valE;
	1: 0xbad
];

reg_inputM = W_valM; # output: sent to register file #POSSIBLE ISSUE
reg_dstM = W_dstM; # output: sent to register file

########## PC and Status updates #############

Stat = W_Stat;



################ Pipeline Register Control #########################

wire loadUse:1;
wire ret_hazard:1; 
wire wrongprediction:1;
loadUse = (E_icode in {MRMOVQ}) && (E_dstM in {reg_srcA, reg_srcB}); 
ret_hazard = [
	D_icode == RET:1;
	E_icode == RET:1;
	M_icode == RET:1;
	1:0;
];

wrongprediction = !e_valid && e_icode == JXX;
### Fetch
stall_F = loadUse || ret_hazard ;


### Decode
bubble_D = (!loadUse && ret_hazard) || wrongprediction;
stall_D = loadUse;

### Execute
bubble_E = loadUse || wrongprediction;

### Memory

### Writeback

