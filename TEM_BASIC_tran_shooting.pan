;#define START_UP   // IF 1 START_UP SEQUENCE IS STARTED, OTHERWISE TRAN STARTS FROM SHOOTING
;#define CBA_SWAP   // IF 1 SWAP IS USED, OTHERWISE BASIC SORT IS USED

#ifdef START_UP
parameters INIT = 0;
#else
parameters INIT = 1;
#endif

;parameters LEVELS = 31 BITS =5
;parameters LEVELS = 63 BITS = 6
;parameters LEVELS = 100 BITS = 7
parameters LEVELS = 127 BITS = 7 


parameters RA=0 XL=0.15 D=0 XDS=0.2 XQS=0.2 PHTYPE=0
parameters PG1=600.0/800 PG2=300.0/600 PG3=550.0/700 PG4=400.0/600 PG5=200.0/250
parameters PG8=750.0/850 PG9=668.5/1000 PG10=600.0/800 PG11=250.0/300 PG12=310.0/350
parameters PG19=300.0/500 PG20=2137.4/4500
parameters ALPHAG=1 ALPHAL=1 BETAL=1 BETAT=1 COST=1

ground electrical gnd

begin power

include "Nordic32_grid.txt"

; +------+
; | HVDC |
; +------+

Vsc1   bus4011   B0C1_a B0C1_b B0C1_c powerec type=3 vrating=400k v0=1/sqrt(3) f0=F0
Vsc2   bus4045   BaA1_a BaA1_b BaA1_c powerec type=3 vrating=400k v0=1/sqrt(3) f0=F0

end

//-----------------------------------------
// MMC PARAMETERS
//-----------------------------------------

parameters P_NOM=800M                    \ // NOMINAL MMC POWER
       VDC_NOM=400k                      \ // NOMINAL MMC POLE-TO-POLE VOLTAGE
       VAC_CONV=VDC_NOM/(2*sqrt(2))      \ // NOMINAL MMC AC LINE-TO-LINE VOLTAGE
       I_NOM=P_NOM/(sqrt(3)*VAC_CONV)    \ // NOMINAL MMC AC CURRENT
       R_GND=1M                          \ // MMC GROUNDING RESISTANCE (DELTA SIDE)
       R_ARM = 1.31m 		         \ // MMC ARM RESISTANCE
       L_ARM=29m			 \ // MMC ARM INDUCTANCE
       C_SM=(10m)*LEVELS/200 		 \ // MMC ARM CAPACITANCE
       VAC_PCC_A1=sqrt(2)*400k/sqrt(3)   \ // NOMINAL MMC AC LINE-TO-GROUND VOLTAGE DC-SLACK/Q MMC
       VAC_PCC_C1=sqrt(2)*400k/sqrt(3)   \ // NOMINAL MMC AC LINE-TO-GROUND VOLTAGE AC2 GRID
       RT=0.363/3   LT=35m/3             \ // Yg/D TRANSFORMER RESISTANCE AND INDUCTANCE (D SIDE)
       RON=1.361m   ROFF=1G              \ // ON- AND OFF- RESISTANCE OF BREAKERS
       F0=50 W_NOM=2*pi*F0               \ // NOMINAL FREQUENCY AND ANGULAR FREQUENCY
       VDIG=1       MAXDCGAIN=1M           // AUXILIARY VARIABLES
       
//-----------------------------------------
// MMC CONTROL PARAMETERS
//-----------------------------------------

parameters KI_P=33   KP_P=0              \ // INTEGRAL AND PROPORTIONAL GAIN (ACTIVE POWER CONTROL)
       KI_Q=33       KP_Q=0              \ // INTEGRAL AND PROPORTIONAL GAIN (REACTIVE POWER CONTROL)
       KI_DC=272     KP_DC=8             \ // INTEGRAL AND PROPORTIONAL GAIN (DC VOLTAGE CONTROL)
       KP_I=0.48     KI_I=149            \ // INTEGRAL AND PROPORTIONAL GAIN (INNER CURRENT CONTROL)
       WC=2          KR=1k      KP=10    \ // CIRCULATING CURRENT CONTROL PARAMETERS
       WN=2*pi*140   XI=0.7              \ // PARAMETERS OF 2ND ORDER FILTER #1 
       WN_1=2*pi*2k  XI_1=0.7              // PARAMETERS OF 2ND ORDER FILTER #2
					   // (FOR PLL AND OTHER FILTERS/CONTROLS, SEE "converter.mod" and "auxiliary.mod")
#ifdef CBA_SWAP
        parameters SWAP       = 1          // compared to BASIC_SORT, it also includes swapping of an arbitrary number of SMs. 
        parameters BASIC_SORT = 0          // compared to BASIC_SORT, it also includes swapping of an arbitrary number of SMs. 
#else
        parameters SWAP       = 0          // compared to BASIC_SORT, it also includes swapping of an arbitrary number of SMs. 
	parameters BASIC_SORT = 1          // all SMs can potentially change their gate signals at threshold crossing.
#endif


//-----------------------------------------
// SIMULATION OPTIONS
//-----------------------------------------

parameters TCROSS=10n TSTOP=100
options rawkeep=yes topcheck=2 ; maxwarns=1000 maxnotices=1000

parameter Save =  ["slk_va","slk_vb","slk_vc",    		                \
	    	   "slk_ia","slk_ib","slk_ic",        				\
		   "pq_va","pq_vb","pq_vc",           				\
		   "pq_ia","pq_ib","pq_ic",           				\
		   "BmC1_pos","BmA1_pos",			 		\
		   "omega1","omega2","omega3","omega4",         		\
		   "omega5","omega8","omega9","omega10",        		\
		   "omega11","omega12","omega19","omega20",      		\
		   "slk_omega","pq_omega",                          		\
		   "bus4011:d","bus4011:q","bus4045:d","bus4045:q", 		\
		   "CmC1.CONV.pow_mod",						\
		   "CmC1.drv_up_a","CmC1.drv_up_b","CmC1.drv_up_c",  		\
		   "CmC1.drv_dw_a","CmC1.drv_dw_b","CmC1.drv_dw_c",  		\
		   "CmC1.vdc_mea","CmC1.idc_pos",				\
		   "CmC1.i_up_a","CmC1.i_up_b","CmC1.i_up_c",        		\
		   "CmC1.i_dw_a","CmC1.i_dw_b","CmC1.i_dw_c",			\
		   "CmA1.CONV.pow_mod",						\
		   "CmA1.drv_up_a","CmA1.drv_up_b","CmA1.drv_up_c",  		\
		   "CmA1.drv_dw_a","CmA1.drv_dw_b","CmA1.drv_dw_c",  		\
		   "CmA1.vdc_mea","CmA1.idc_pos",                    		\
		   "CmA1.i_up_a","CmA1.i_up_b","CmA1.i_up_c",        		\
		   "CmA1.i_dw_a","CmA1.i_dw_b","CmA1.i_dw_c",        		\
		   "CmC1.Arm_up_a:v_cap_previous#1",                   		\
		   "CmC1.Arm_up_a:v_cap_previous#2",                   		\
		   "CmC1.Arm_up_a:v_cap_previous#3",                   		\
		   "CmC1.Arm_up_a:v_cap_previous#4",                   		\
		   "CmC1.Arm_up_a:v_cap_previous#5",                   		\
		   "CmC1.Arm_up_a:v_cap_previous#6",                   		\
		   "CmC1.Arm_up_a:v_cap_previous#7",                   		\
		   "CmC1.Arm_up_a:v_cap_previous#8",                   		\
		   "CmC1.Arm_up_a:v_cap_previous#9",                   		\
		   "CmC1.Arm_up_a:v_cap_previous#10",                   	\
		   "CmA1.Arm_up_a:v_cap_previous#1",                   		\
		   "CmA1.Arm_up_a:v_cap_previous#2",                   		\
		   "CmA1.Arm_up_a:v_cap_previous#3",                   		\
		   "CmA1.Arm_up_a:v_cap_previous#4",                   		\
		   "CmA1.Arm_up_a:v_cap_previous#5",                   		\
		   "CmA1.Arm_up_a:v_cap_previous#6",                   		\
		   "CmA1.Arm_up_a:v_cap_previous#7",                   		\
		   "CmA1.Arm_up_a:v_cap_previous#8",                   		\
		   "CmA1.Arm_up_a:v_cap_previous#9",                   		\
		   "CmA1.Arm_up_a:v_cap_previous#10"]                   	

TEM_BASIC_tran_shooting tran nettype=1 uic=3 stop=1 tstart=150m                 \
			     devvars=true saman=true load="NordicSfm.sh"        \
		             annotate=3 method=2 maxord=2 cmin=false acntrl=3   \
			     sparse=2 tinc=1 dgionly=true tmin=1n               \
			     tmax=0.01/F0 skip=2 smnc=0.1 keepmatrixorder=1     \
			     iabstol=1m  vreltol=1m ireltol=1m vabstol=1m       \
			     forcetps=true timepoints=0.1u savelist=Save

TEM_BASIC_tran_shooting_B tran nettype=1 uic=3 stop=TSTOP tstart=150m             \
			     devvars=true saman=true load="NordicSfm.sh"        \
		             annotate=3 method=2 maxord=2 cmin=false acntrl=3   \
			     sparse=2 tinc=1 dgionly=true tmin=1n               \
			     tmax=0.01/F0 skip=2 smnc=0.1 keepmatrixorder=1     \
			     iabstol=1m  vreltol=1m ireltol=1m vabstol=1m       \
			     forcetps=true timepoints=1u savelist=Save


//---------------------------------------------
//  THE SIMULATED THREE-PHASE CIRCUIT
//---------------------------------------------

Eflt  gFlt    gnd    vsource vdc=0

#ifdef START_UP
Von on gnd  vsource v1=0 v2=VDIG td=3/F0 tr=1u width=TSTOP+1 period=TSTOP+2
#else
Von on gnd  vsource vdc=VDIG
#endif

//--------------------------------------------
//  AC GRID (AC1) -- MMC-PQ SIDE
//--------------------------------------------

Brk_pq_a B0C1_a CmC1_a pq_acon  gnd  AC_SW  RON=1m ROFF=ROFF
Brk_pq_b B0C1_b CmC1_b pq_acon  gnd  AC_SW  RON=1m ROFF=ROFF
Brk_pq_c B0C1_c CmC1_c pq_acon  gnd  AC_SW  RON=1m ROFF=ROFF

Rxa   B0C1_a       xa1   resistor  r=1000
Cxa      xa1    CmC1_a   capacitor c=100n
Rxb   B0C1_b       xb1   resistor  r=1000
Cxb      xb1    CmC1_b   capacitor c=100n
Rxc   B0C1_c       xc1   resistor  r=1000
Cxc      xc1    CmC1_c   capacitor c=100n

CONV_PCC_PQ CmC1_a CmC1_b CmC1_c pq_a pq_b pq_c pq_va pq_vb pq_vc pq_ia pq_ib pq_ic on \
                CONV_PCC V1=VAC_PCC_A1 V2=VAC_CONV/sqrt(3) L=LT

CmC1 pq_a pq_b pq_c BmC1_pos BmC1_neg pq_va pq_vb pq_vc pq_ia pq_ib pq_ic \
                 pq_omega pq_acon on pq_blocked MMC_PQ idx = 1


//--------------------------------------------
//  DC SYSTEM
//--------------------------------------------

TLINE1 BmC1_pos  m1_pos   gnd FREQ_DEPENDENT_CABLE KM=100 
TLINE2 m1_pos    BmA1_pos gnd FREQ_DEPENDENT_CABLE KM=100 
TLINE3 BmC1_neg  m1_neg   gnd FREQ_DEPENDENT_CABLE KM=100 
TLINE4 m1_neg    BmA1_neg gnd FREQ_DEPENDENT_CABLE KM=100 

//--------------------------------------------
//  AC Grid (AC2)  -- MMC -DC-SLACK/Q side
//--------------------------------------------

Brk_slk_a BaA1_a CmA1_a slk_acon  gnd  AC_SW  RON=1m ROFF=ROFF
Brk_slk_b BaA1_b CmA1_b slk_acon  gnd  AC_SW  RON=1m ROFF=ROFF
Brk_slk_c BaA1_c CmA1_c slk_acon  gnd  AC_SW  RON=1m ROFF=ROFF

Rya   BaA1_a       ya1   resistor  r=100
Cya      ya1    CmA1_a   capacitor c=100n
Ryb   BaA1_b       yb1   resistor  r=100
Cyb      yb1    CmA1_b   capacitor c=100n
Ryc   BaA1_c       yc1   resistor  r=100
Cyc      yc1    CmA1_c   capacitor c=100n

CONV_PCC_SLK CmA1_a CmA1_b CmA1_c slk_a slk_b slk_c \
	slk_va slk_vb slk_vc slk_ia slk_ib slk_ic on \
	CONV_PCC V1=VAC_PCC_C1 V2=VAC_CONV/sqrt(3) L=LT

CmA1 slk_a slk_b slk_c BmA1_pos BmA1_neg \
     slk_va slk_vb slk_vc slk_ia slk_ib slk_ic \
     slk_omega slk_acon on slk_blocked MMC_SLKDCQ idx = 2

//--------------------------------------------
// MMC1 (PQ)
//--------------------------------------------

subckt MMC_PQ a1 b1 c1 dc_pos dc_neg va vb vc ia ib ic omega acon on blocked

Idc_pos   idc_pos gnd i_up_a i_up_b i_up_c vcvs func=v(i_up_a)+v(i_up_b)+v(i_up_c)
Idc_neg   idc_neg gnd i_dw_a i_dw_b i_dw_c vcvs func=v(i_dw_a)+v(i_dw_b)+v(i_dw_c)

Rgnda a1  gnd   resistor r=R_GND
Rgndb b1  gnd   resistor r=R_GND
Rgndc c1  gnd   resistor r=R_GND

CONV a1 b1 c1 dc_pos dc_neg va vb vc ia ib ic \
     vdp vqp vdn vqn idp iqp idn iqn idp_ref iqp_ref idn_ref iqn_ref \
     i_up_a i_up_b i_up_c \
     i_dw_a i_dw_b i_dw_c \
     drv_up_a drv_up_b drv_up_c \
     drv_dw_a drv_dw_b drv_dw_c \
     omega idc_pos vdc_mea blocked acon COMPL_CONV L=LT+L_ARM/2 W_NOM=W_NOM 

// AC-Q REFERENCE AND REGULATION
Qref qref  gnd   vsource vdc=0
Qreg iqp_ref vdp vqp vdn vqn idp iqp idn iqn qref blocked Q_REG \
	MAX=1.2 MIN=-1.2 KP=0 KI=KI_Q CF=1M

// AC-P REFERENCE AND REGULATION (WITH DC-V DEAD-BAND)
#ifdef START_UP
Pref pref  gnd   vsource vdc=0 v1=0 v2=-0.4 td=150m-2u tr=1u \
                         width=TSTOP+1 period=TSTOP+2
#else
Pref pref  gnd   vsource vdc=-0.4
#endif

Preg idp_mod vdp vqp vdn vqn idp iqp idn iqn pref blocked P_REG \
	MAX=1.2 MIN=-1.2 KP=KP_P KI=KI_P CF=1M
Vdcdb vdc_mea delta_idp deadband_on DEADBAND TON=500m
Idref idp_ref gnd idp_mod delta_idp vcvs func= limit(v(idp_mod) - v(delta_idp),-1.2,1.2)

// D-Q CURRENT REFERENCES (NEGATIVE SEQUENCE)
// KEEP AC CURRENTS BALANCED
Idn_ref idn_ref gnd vsource vdc=0
Iqn_ref iqn_ref gnd vsource vdc=0

// MMC PROTECTION (MUST BE MODIFIED)
Blk acon on blocked vdp vqp idc_pos idc_neg BLK_CTRL


// ================= //
// MMC ARM STRUCTURE //
// ================= //

include "netlist_TEM.txt"

// ARM CURRENT RETRIEVAL
Iup_a  i_up_a  gnd ccvs sensedev="Lop_a" gain1=1
Idw_a  i_dw_a  gnd ccvs sensedev="Lon_a" gain1=-1
Iup_b  i_up_b  gnd ccvs sensedev="Lop_b" gain1=1
Idw_b  i_dw_b  gnd ccvs sensedev="Lon_b" gain1=-1
Iup_c  i_up_c  gnd ccvs sensedev="Lop_c" gain1=1
Idw_c  i_dw_c  gnd ccvs sensedev="Lon_c" gain1=-1

// ================= //
//                   //
// ================= //



// -------------------------------------------------
// END OF MMC NETLIST DEFINITION
// ------------------------------------------------

ends

//--------------------------------------------
// MMC2 (SLACK DC Q)
//--------------------------------------------

subckt MMC_SLKDCQ a1 b1 c1 dc_pos dc_neg va vb vc ia ib ic omega acon on blocked

Idc_pos   idc_pos gnd i_up_a i_up_b i_up_c vcvs func=v(i_up_a)+v(i_up_b)+v(i_up_c)
Idc_neg   idc_neg gnd i_dw_a i_dw_b i_dw_c vcvs func=v(i_dw_a)+v(i_dw_b)+v(i_dw_c)

Rgnda a1  gnd   resistor r=R_GND
Rgndb b1  gnd   resistor r=R_GND
Rgndc c1  gnd   resistor r=R_GND

CONV a1 b1 c1 dc_pos dc_neg va vb vc ia ib ic \
     vdp vqp vdn vqn idp iqp idn iqn idp_ref iqp_ref idn_ref iqn_ref \
     i_up_a i_up_b i_up_c \
     i_dw_a i_dw_b i_dw_c \
     drv_up_a drv_up_b drv_up_c \
     drv_dw_a drv_dw_b drv_dw_c \
     omega idc_pos vdc_mea blocked acon COMPL_CONV L=LT+L_ARM/2 W_NOM=W_NOM 

// DC-V REFERENCE AND REGULATION
Vdcref dcref gnd   vsource vdc=VDC_NOM/VDC_NOM

Vdcpi_mod idp_ref vdc_mea dcref gnd PI_REG \
	KP=KP_DC KI=KI_DC MAX=1.5 MIN=-1.5 CF=1M


// AC-Q REFERENCE AND REGULATION
Qref qref  gnd   vsource vdc=0
Qreg iqp_ref vdp vqp vdn vqn idp iqp idn iqn qref blocked Q_REG \
	MAX=1.2 MIN=-1.2 KP=0 KI=KI_Q CF=1M

// D-Q CURRENT REFERENCES (NEGATIVE SEQUENCE)
// KEEP AC CURRENTS BALANCED 
Idn_ref idn_ref gnd vsource vdc=0
Iqn_ref iqn_ref gnd vsource vdc=0

// MMC PROTECTION (MUST BE MODIFIED)
Blk acon on blocked vdp vqp idc_pos idc_neg BLK_CTRL 


// ================= //
// MMC ARM STRUCTURE //
// ================= //

include "netlist_TEM.txt"

// ARM CURRENT RETRIEVAL
Iup_a  i_up_a  gnd ccvs sensedev="Lop_a" gain1=1
Idw_a  i_dw_a  gnd ccvs sensedev="Lon_a" gain1=-1
Iup_b  i_up_b  gnd ccvs sensedev="Lop_b" gain1=1
Idw_b  i_dw_b  gnd ccvs sensedev="Lon_b" gain1=-1
Iup_c  i_up_c  gnd ccvs sensedev="Lop_c" gain1=1
Idw_c  i_dw_c  gnd ccvs sensedev="Lon_c" gain1=-1

// ================= //
//                   //
// ================= //

ends



// -------------------------------------------------
// DEFINITION OF OTHER MODELS AND FILES
// ------------------------------------------------

verilog_include verilog_TEM.v

include auxiliary.mod
include converter.mod

model      ABCDQ0 nport veriloga="abcdq0.va"   verilogaprotected=yes
model      DQ0ABC nport veriloga="dq0abc.va"   verilogaprotected=yes
model       UVBLK nport veriloga="uvblk.va"    verilogaprotected=yes
model       OCBLK nport veriloga="ocblk.va"    verilogaprotected=yes
model      BLKTOT nport veriloga="blktot.va"   verilogaprotected=yes
model    DEADBAND nport veriloga="deadband.va" verilogaprotected=yes
model       AC_SW nport veriloga="acsw.va" verilogaprotected=yes
model        ONSW vswitch ron=RT  roff=10k voff=0.4*VDIG von=0.6*VDIG
model          SW vswitch ron=RON roff=1M voff=0.2*VDIG von=0.8*VDIG
model         DIO diode imax=10k rs=RON
model     DIO_BLK diode imax=30k rs=RON*LEVELS n=1*LEVELS is=1n compact=1
model         AVR nport veriloga="avr.va" verilogaprotected=yes
model        ULTC nport veriloga="ultc.va" verilogaprotected=no \
                        verilogatrace=["Vmag","Vref","Upper","Lower"]
model         HTG nport veriloga="htg.va" verilogaprotected=yes \
                        verilogatrace=["OmegaErr","PiOut","Reset"]
model     MMC_ARM nport veriloga="TEM.va"  verilogaprotected=yes \
			verilogatrace=["v_cap_previous","gate"]
