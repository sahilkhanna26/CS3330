# -*-sh-*- # this line enables partial syntax highlighting in emacs

######### The PC #############
register fF { pc:64 = 0; }

register fD{
	icode:4 = NOP;
	rA:4 = REG_NONE;
	rB:4 = REG_NONE;
	Stat:3 = STAT_AOK;
	
}

register dE{
	Stat:3 = STAT_AOK;
	icode:4 = 0;
	dstM : 4 = REG_NONE;
	valA :64 = 0;
	valB : 64 = 0;
}

register eM{
	Stat:3 = STAT_AOK;
	icode:4 = 0;
	dstM:4 = REG_NONE;
	srcA:4 = REG_NONE;
	srcB:4 = REG_NONE;
}


register mW{
	Stat:3 = STAT_AOK;
	icode:4 = 0;
	dstM:4 = REG_NONE;
	valM: 64=0;
}


########## Fetch #############
pc = F_pc;

wire icode:4, ifun:4, rA:4, rB:4, valC:64;
wire loadUse:1; 

loadUse = (E_icode == MRMOVQ && e_dstM == e_srcB);

icode = i10bytes[4..8];
ifun = i10bytes[0..4];
rA = i10bytes[12..16];
rB = i10bytes[8..12];


valC = [
	icode in { JXX } : i10bytes[8..72];
	1 : i10bytes[16..80];
];

wire offset:64, valP:64;
offset = [
	icode in { HALT, NOP, RET } : 1;
	icode in { RRMOVQ, OPQ, PUSHQ, POPQ } : 2;
	icode in { JXX, CALL } : 9;
	1 : 10;
];
valP = F_pc + offset;
stall_F = loadUse; 

f_rA = rA;
f_rB = rB;
f_icode = icode;


########## Decode #############

d_icode = D_icode;

d_Stat = D_Stat;


reg_srcA = [
	D_icode in {RMMOVQ} : D_rA;
	1 : REG_NONE;
];

d_valA = [
  reg_srcA == m_dstM : m_valM;
  reg_srcA == W_dstM : W_valM; 
  1 : reg_outputA;
  ];
stall_D = loadUse;


reg_srcB = [
	D_icode in {RMMOVQ, MRMOVQ} : D_rB;
	1 : REG_NONE;
];

d_valB = [
  	reg_srcB == m_dstM : m_valM;
 	reg_srcB == W_dstM : W_valM; 
  	1 : reg_outputB;
  ];

 d_dstM = [ 
 	D_icode==MRMOVQ :D_rA;
 	1: REG_NONE;

 ];



########## Execute #############



e_dstM = E_dstM;
e_srcA = reg_srcA;
e_srcB = reg_srcB;
e_icode= E_icode;
e_Stat = E_Stat;

/* keep the PC the same next cycle */

    
/* keep same instruction in decode next cycle */

    
/* send nop to execute next cycle */
bubble_E = loadUse;


wire operand1:64, operand2:64;



operand1 = [
	icode in { MRMOVQ, RMMOVQ } : valC;
	1: 0;
];
operand2 = [
	icode in { MRMOVQ, RMMOVQ } : reg_outputB;
	1: 0;
];

wire valE:64;

valE = [
	icode in { MRMOVQ, RMMOVQ } : operand1 + operand2;
	1 : 0;
];



########## Memory #############


m_icode = M_icode;
m_valM = mem_output;
m_dstM = M_dstM;
m_Stat = M_Stat;



mem_readbit = icode in { MRMOVQ };
mem_writebit = icode in { RMMOVQ };
mem_addr = [
	icode in { MRMOVQ, RMMOVQ } : valE;
        1: 0xBADBADBAD;
];
mem_input = [
	icode in { RMMOVQ } : reg_outputA;
        1: 0xBADBADBAD;
];

########## Writeback #############


reg_dstM = W_dstM;
reg_inputM = W_valM;

f_Stat = [
		f_icode == HALT :STAT_HLT;
		1:STAT_AOK;
];

Stat = W_Stat;
f_pc = valP;



