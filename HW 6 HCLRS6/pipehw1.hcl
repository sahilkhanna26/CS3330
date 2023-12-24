########## the PC and condition codes registers #############
register fF { pc:64 = 0; }





########## Fetch #############
register fD{
	icode: 4 = NOP;
	valC: 64 = 0;
	ifun:4 = 0;
	Stat:3 = STAT_AOK;
	rA:4 = REG_NONE;
    rB:4 = REG_NONE;
}

pc = F_pc;
f_ifun = i10bytes[0..4];
f_icode = i10bytes[4..8];


f_Stat = [
	f_icode == HALT: STAT_HLT;
	f_icode == RRMOVQ: STAT_AOK;
	f_icode == IRMOVQ: STAT_AOK;
	f_icode == OPQ: STAT_AOK;
	f_icode == CMOVXX: STAT_AOK;
	f_icode == NOP: STAT_AOK;
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
	1:0;
];

f_pc = [
    f_icode == NOP: F_pc+1;
    f_icode == HALT: F_pc+1;
    f_icode == RET: F_pc+1;
    f_icode == NOP: F_pc+1;
    f_icode == RRMOVQ: F_pc+2;
    f_icode == OPQ: F_pc+2;
    f_icode == PUSHQ: F_pc+2;
    f_icode == POPQ: F_pc+2;
    f_icode == JXX: F_pc+9;
    f_icode == CALL: F_pc+9;
    1: F_pc+10;
  ];

########## Decode #############

register dE{
	icode: 4 = NOP;
	ifun:4 = 0;
	valC: 64 = 0;
	dstE:4 = REG_NONE;
	Stat:3 = STAT_AOK;
	valA:64 = 0;
	valB: 64 = 0;
	srcA:4 = REG_NONE;
	srcB:4 = REG_NONE;
}
d_icode = D_icode;
d_valC = D_valC;
d_ifun = D_ifun;
d_Stat = D_Stat;


# source selection
reg_srcA = [
	d_icode== OPQ: D_rA;
	d_icode== RRMOVQ: D_rA;
	d_icode == CMOVXX: D_rA;
	1 : REG_NONE;
];
d_srcA = reg_srcA;
reg_srcB = [
	d_icode == OPQ: D_rB;
	1 : REG_NONE;
];
d_srcB = reg_srcB;

d_valA = [
	((reg_srcA == e_dstE) && (reg_srcA != REG_NONE)):e_valE;
	((reg_srcA == m_dstE)&& (reg_srcA != REG_NONE)): m_valE;
	((reg_srcA == reg_dstE && reg_srcA != REG_NONE)): reg_inputE;
	
	1: reg_outputA;
];
d_valB = [
	((reg_srcB == e_dstE)&&(reg_srcB != REG_NONE)):e_valE;
	((reg_srcB == m_dstE)&& (reg_srcB != REG_NONE)): m_valE;
	((reg_srcB == reg_dstE && reg_srcB != REG_NONE)): reg_inputE;
	
	1: reg_outputB;
];

d_dstE = [
	d_icode == RRMOVQ : D_rB;
	d_icode == IRMOVQ : D_rB;
	d_icode == CMOVXX: D_rB;
	d_icode == OPQ : D_rB;
	1:REG_NONE;
];




########## Execute #############
register eM {
	icode: 4 = NOP;
	Stat:3 = STAT_AOK;
	valA:64 = 0;
	valB:64 = 0;
	valC:64 = 0;
	valE:64 = 0;
	dstE:4 = REG_NONE;
}



register cC {
     SF:1 = 0;
     ZF:1 = 1;
 }


 c_ZF = (e_valE == 0);
 c_SF = (e_valE >= 0x8000000000000000);

 stall_C = (e_icode != OPQ);

conditionsMet = [
    E_ifun == ALWAYS : true;
    E_ifun == LE : C_SF || C_ZF;
    E_ifun == LT : C_SF;
    E_ifun == EQ : C_ZF;
    E_ifun == NE : !C_ZF;
    E_ifun == GE : !C_SF; 
    E_ifun == GT : !C_SF && !C_ZF;
    1 : false;
];

e_icode = E_icode;
e_Stat = E_Stat;
e_valC = E_valC;
e_valA = E_valA;
e_valB = E_valB;

e_valE = [
	e_icode == RRMOVQ : e_valA;
	e_icode == IRMOVQ : e_valC;
	e_icode == OPQ && E_ifun == SUBQ : e_valB - e_valA;
	e_icode == OPQ && E_ifun == ADDQ : e_valA + e_valB;
	e_icode == OPQ && E_ifun == XORQ : e_valA ^ e_valB;
	e_icode == OPQ && E_ifun == ANDQ : e_valA & e_valB;
	1 : 0;
];

e_dstE = [
	!conditionsMet && e_icode == CMOVXX : REG_NONE;
    e_icode == IRMOVQ: E_dstE;
    e_icode == RRMOVQ: E_dstE;

    e_icode == OPQ:  E_dstE;
    1:REG_NONE;
];


########## Memory #############
register mW {
	icode: 4 = NOP;
	Stat:3 = STAT_AOK;
	valA:64 = 0;
	valB:64 = 0;
	valC:64 = 0;
	valE:64 = 0;
	dstE:4 = REG_NONE;


}
m_icode = M_icode;
m_Stat = M_Stat;
m_valC = M_valC;
m_dstE = M_dstE;
m_valA = M_valA;
m_valB = M_valB;
m_valE = M_valE;
########## Writeback #############


# destination selection
reg_dstE = W_dstE;

reg_inputE = [ # unlike book, we handle the "forwarding" actions (something + 0) here
	W_icode == RRMOVQ : W_valA;
	W_icode == IRMOVQ : W_valC;
	W_icode == OPQ : W_valE;
	1: 0xbad
];


########## PC and Status updates #############

Stat = W_Stat;

