# -*-sh-*- # this line enables partial syntax highlighting in emacs

######### The PC #############
register fF { pc:64 = 0; }


########## Fetch #############
pc = F_pc;

wire icode:4, ifun:4, rA:4, rB:4, valC:64;
wire loadUse:1; 

loaduse = ( E_icode == MRMOVQ && (d_dstM == d_srcA || d_dstM == d_srcB));

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

########## Decode #############
register fD{
	icode:4 = nop;
	rA:4 = REG_NONE;
	rB:4 = REG_NONE;
	
}

reg_srcA = [
	d_icode in {RMMOVQ} : rA;
	1 : REG_NONE;
];

d_valA = [
  reg_srcA == REG_NONE : 0;
  reg_srcA == m_dstM : m_valM;
  reg_srcA == W_dstM : W_valM; 
  1 : reg_outputA;
  ];

reg_outputA;

reg_srcB = [
	d_icode in {RMMOVQ, MRMOVQ} : rB;
	1 : REG_NONE;
];

d_valB = [
	reg_srcB == REG_NONE : 0;
  	reg_srcB == m_dstM : m_valM;
 	reg_srcB == W_dstM : W_valM; 
  1 : reg_outputB;
  ];

 d_dstM = [ 
 	d_icode==MRMOVQ : rA;
 	1: REG_NONE;

 ];

reg_dstM = [
    d_icode in {MRMOVQ} : rA;
    1: REG_NONE;
];

d_valA = [];
########## Execute #############
register dE{
	srcA : 4 = REG_NONE;
	srcB : 4 = REG_NONE;
	dstM : 4 = REG_NONE;
}

/* keep the PC the same next cycle */
stall_F = loadUse;  /* or add a MUX for f_pc */
    
/* keep same instruction in decode next cycle */
stall_D = loadUse;
    
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
register eM{
	
}


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
register mW{
	
}


reg_dstM = [ 
	icode in {MRMOVQ} : rA;
	1: REG_NONE;
];
reg_inputM = [
	icode in {MRMOVQ} : mem_output;
        1: 0xBADBADBAD;
];


Stat = [
	icode == HALT : STAT_HLT;
	icode > 0xb : STAT_INS;
	1 : STAT_AOK;
];

f_pc = valP;



