// -----------------------------
//  CONVERTER CIRCUITS:
//
//  CONV_PCC
//  COMPL_CONV
// ----------------------------

// -------------------------------------------------------------------------------------
//  CONV_PCC
//  It includes a Yg/D transformer and a RL filter used to connect an MMC to the AC side. 
//  A three-phase switch is used to separate the MMC from the grid, if needed.
//  Meaning of terminals:
//  "in_a", "in_b", "in_c": MMC input port.
//  "a1", "b1", "c1"      : MMC output port.
//  "a3", "b3", "c3"      : MMC voltages at point of common coupling (PCC).
//  "ia", "ib", "ic"      : MMC currents at PCC. (If >0, power flows towards AC grid).
//  "on"                  : terminal governing the status of the three-phase switch. 
// ------------------------------------------------------------------------------------

subckt CONV_PCC in_a in_b in_c a1 b1 c1 a3 b3 c3 ia ib ic on
parameters V1=1 V2=1 L=1

;TRANFORMER
T1  in_a gnd  a3 pqs transformer t1=V1 t2=V2
T2  in_b gnd  b3 pqs transformer t1=V1 t2=V2
T3  in_c gnd  c3 pqs transformer t1=V1 t2=V2

Rpqs pqs gnd resistor r=10k

Lta a2 a3 inductor l=L ic=0
Ltb b2 b3 inductor l=L ic=0
Ltc c2 c3 a2 a3 b2 b3 vcvs gain1=-1 gain2=-1

Rta a1 a2 on  gnd  ONSW
Rtb b1 b2 on  gnd  ONSW
Rtc c1 c2 on  gnd  ONSW

; Current sensing
Ia0 ia gnd ccvs sensedev="Lta" gain1=1
Ib0 ib gnd ccvs sensedev="Ltb" gain1=1
Ic0 ic gnd ccvs sensedev="Ltc" gain1=1

ends

// -----------------------------
//  COMPL_CONV
// ----------------------------
subckt COMPL_CONV a1 b1 c1 dc_pos dc_neg va_raw vb_raw vc_raw ia_raw ib_raw ic_raw \
            vdp vqp vdn vqn idp iqp idn iqn \
            idp_ref iqp_ref idn_ref iqn_ref \
	    ia_up ib_up ic_up \
	    ia_lo ib_lo ic_lo \
	    drv_ua drv_ub drv_uc \
	    drv_la drv_lb drv_lc \
	    omega idc_pos vdc_mea blocked on

parameter L=1 
parameter L_PU=L/(VAC_CONV^2/(P_NOM*W_NOM))
parameter W_NOM=1

// AC CURRENT AND VOLTAGE MEASUREMENTS (WITH FILTER)
// POWER MEASUREMENT (WITH FILTER)
Ia ia gnd ia_raw gnd svcvs numer=[WN_1^2] denom=[WN_1^2,2*XI_1*WN_1,1] ic=0 
Ib ib gnd ib_raw gnd svcvs numer=[WN_1^2] denom=[WN_1^2,2*XI_1*WN_1,1] ic=0
Ic ic gnd ic_raw gnd svcvs numer=[WN_1^2] denom=[WN_1^2,2*XI_1*WN_1,1] ic=0
Va va gnd va_raw gnd svcvs numer=[WN_1^2] denom=[WN_1^2,2*XI_1*WN_1,1] ic=0
Vb vb gnd vb_raw gnd svcvs numer=[WN_1^2] denom=[WN_1^2,2*XI_1*WN_1,1] ic=0
Vc vc gnd vc_raw gnd svcvs numer=[WN_1^2] denom=[WN_1^2,2*XI_1*WN_1,1] ic=0

// POWER MEASUREMENT (WITH FILTER)
Pwr_mod pow_mod gnd ia ib ic va vb vc vcvs func=v(ia)*v(va)+v(ib)*v(vb)+v(ic)*v(vc)
;Pwr pow gnd pow_mod gnd svcvs numer=[WN^2] denom=[WN^2,2*XI*WN,1]
Pwr pow gnd pow_mod gnd vcvs gain=1

// DC VOLTAGE MEASUREMENT (WITH FILTER)
VdcMea vdc_mea  gnd dc_pos  dc_neg  svcvs dcgain=1/VDC_NOM numer=[(2*pi*70)^2] \
                                    denom=[(2*pi*70)^2,2*XI_1*(2*pi*70),1] ic=1 ;skipck=yes

// CIRCULATING CURRENT MEASUREMENT
;Iza iza gnd ia_up ia_lo on vcvs func=0.5*(v(ia_up)+v(ia_lo))*((v(on) > 0.5*VDIG) ? 1:0)
;Izb izb gnd ib_up ib_lo on vcvs func=0.5*(v(ib_up)+v(ib_lo))*((v(on) > 0.5*VDIG) ? 1:0)
;Izc izc gnd ic_up ic_lo on vcvs func=0.5*(v(ic_up)+v(ic_lo))*((v(on) > 0.5*VDIG) ? 1:0)

Iza iza gnd ia_up ia_lo vcvs func=0.5*(v(ia_up)+v(ia_lo))
Izb izb gnd ib_up ib_lo vcvs func=0.5*(v(ib_up)+v(ib_lo))
Izc izc gnd ic_up ic_lo vcvs func=0.5*(v(ic_up)+v(ic_lo))

// PARK TRANSFORM OF PCC VOLTAGE AND CURRENT (ABC TO DQ0) 
Vdq0_pos vdp_raw vqp_raw va vb vc teta ABCDQ0 GAIN=(2/3)/(VAC_CONV)      TETA_GAIN=+1
Vdq0_neg vdn_raw vqn_raw va vb vc teta ABCDQ0 GAIN=(2/3)/(VAC_CONV)      TETA_GAIN=-1
Idq0_pos idp_raw iqp_raw ia ib ic teta ABCDQ0 GAIN=(2/3)/(I_NOM*sqrt(2)) TETA_GAIN=+1
Idq0_neg idn_raw iqn_raw ia ib ic teta ABCDQ0 GAIN=(2/3)/(I_NOM*sqrt(2)) TETA_GAIN=-1

// PLL (PCC VOLTAGE IS USED)  
Ipll w_err    gnd  vqp_raw    gnd vcvs  gain=1
Dw      dw    gnd  w_err gnd  svcvs numer=[122.5k, 490] denom=[0,1] maxdcgain=MAXDCGAIN ic=0
;Dw      dw    gnd  w_err gnd  svcvs numer=[0.8615G, 9.324M, 1515, 16.4] denom=[197136,452,1] maxdcgain=MAXDCGAIN  ic=0
;Dw      dw    gnd  w_err gnd  svcvs numer=[122.5k, 100] denom=[0,1] maxdcgain=MAXDCGAIN ic=0
Wnew  omega   gnd  dw         vcvs  func=limit(v(dw),-10,10) + W_NOM 
Wpu  omega_pu   gnd  omega         vcvs  func=v(omega)/W_NOM 
Teta  teta    gnd  dw gnd     svcvs numer=[1] denom=[0,1] maxdcgain=MAXDCGAIN ic=0 

// ADDITIONAL FILTERS FOR D-Q, P-N VOLTAGES
Vdp_mod  vdp_mod gnd  vdp_raw gnd svcvs dcgain=1 numer=[1] denom=[1, 1/(2*pi*11)]
Vqp_mod  vqp_mod gnd  vqp_raw gnd svcvs dcgain=1 numer=[1] denom=[1, 1/(2*pi*11)]
Vdn_mod  vdn_mod gnd  vdn_raw gnd svcvs dcgain=1 numer=[1] denom=[1, 1/(2*pi*11)]
Vqn_mod  vqn_mod gnd  vqn_raw gnd svcvs dcgain=1 numer=[1] denom=[1, 1/(2*pi*11)]

/*
Vdp_mod  vdp_mod gnd  vdp_raw gnd vcvs gain=1 
Vqp_mod  vqp_mod gnd  vqp_raw gnd vcvs gain=1 
Vdn_mod  vdn_mod gnd  vdn_raw gnd vcvs gain=1 
Vqn_mod  vqn_mod gnd  vqn_raw gnd vcvs gain=1 
*/

// NOTCH FILTERS (REQUIRED TO ELIMINATE 2*W COMPONENT IN D-Q VOLTAGES AND CURRENTS) (POSITIVE SEQUENCE)
Vdp_filt vdp gnd vdp_mod gnd svcvs dcgain=1 numer=[(2*W_NOM)^2,0,1] denom=[(2*W_NOM)^2,2*W_NOM*0.1,1]
Vqp_filt vqp gnd vqp_mod gnd svcvs dcgain=1 numer=[(2*W_NOM)^2,0,1] denom=[(2*W_NOM)^2,2*W_NOM*0.1,1]
Idp_filt idp gnd idp_raw gnd svcvs dcgain=1 numer=[(2*W_NOM)^2,0,1] denom=[(2*W_NOM)^2,2*W_NOM*0.1,1]
Iqp_filt iqp gnd iqp_raw gnd svcvs dcgain=1 numer=[(2*W_NOM)^2,0,1] denom=[(2*W_NOM)^2,2*W_NOM*0.1,1]

// NOTCH FILTERS (REQUIRED TO ELIMINATE 2*W COMPONENT IN D-Q VOLTAGES AND CURRENTS) (NEGATIVE SEQUENCE)
Vdn_filt vdn gnd vdn_mod gnd svcvs dcgain=1 numer=[(2*W_NOM)^2,0,1] denom=[(2*W_NOM)^2,2*W_NOM*0.1,1]
Vqn_filt vqn gnd vqn_mod gnd svcvs dcgain=1 numer=[(2*W_NOM)^2,0,1] denom=[(2*W_NOM)^2,2*W_NOM*0.1,1]
Idn_filt idn gnd idn_raw gnd svcvs dcgain=1 numer=[(2*W_NOM)^2,0,1] denom=[(2*W_NOM)^2,2*W_NOM*0.1,1]
Iqn_filt iqn gnd iqn_raw gnd svcvs dcgain=1 numer=[(2*W_NOM)^2,0,1] denom=[(2*W_NOM)^2,2*W_NOM*0.1,1]

// INNER CURRENT LOOP
LOOP_DP udp idp vdp iqp idp_ref omega INNER_LOOP KP=KP_I KI=KI_I L=L_PU GAIN=-1 W=W_NOM MAXGAIN=MAXDCGAIN
LOOP_QP uqp iqp vqp idp iqp_ref omega INNER_LOOP KP=KP_I KI=KI_I L=L_PU GAIN=+1 W=W_NOM MAXGAIN=MAXDCGAIN
LOOP_DN udn idn vdn iqn idn_ref omega INNER_LOOP KP=KP_I KI=KI_I L=L_PU GAIN=+1 W=W_NOM MAXGAIN=MAXDCGAIN
LOOP_QN uqn iqn vqn idn iqn_ref omega INNER_LOOP KP=KP_I KI=KI_I L=L_PU GAIN=-1 W=W_NOM MAXGAIN=MAXDCGAIN

// INVERSE PARK TRANSFORM OF REFERENCE VOLTAGES
UABCP ufp_a ufp_b ufp_c udp uqp gnd teta DQ0ABC GAIN=VAC_CONV TETA_GAIN=+1
UABCN ufn_a ufn_b ufn_c udn uqn gnd teta DQ0ABC GAIN=VAC_CONV TETA_GAIN=-1

UFA uf_a gnd ufp_a ufn_a vcvs func=v(ufp_a)+v(ufn_a)
UFB uf_b gnd ufp_b ufn_b vcvs func=v(ufp_b)+v(ufn_b)
UFC uf_c gnd ufp_c ufn_c vcvs func=v(ufp_c)+v(ufn_c)

//  CIRCULATING CURRENT CONTROL
// DC CURRENT FILTERING. 1/3 IS REQUIRED TO GET REFERENCE CIRCULATING CURRENT FOR EACH PHASE.
Idc_filt idc_filt gnd idc_pos gnd svcvs numer=[1/3*(2*pi*25)^2] denom=[(2*pi*25)^2,2*XI_1*(2*pi*25),1] dcgain=1/3 ic=0 

e_a uz_a idc_filt iza CIRC_REG MAXDCGAIN=MAXDCGAIN W_NOM=W_NOM KR=KR KP=KP WC=WC
e_b uz_b idc_filt izb CIRC_REG MAXDCGAIN=MAXDCGAIN W_NOM=W_NOM KR=KR KP=KP WC=WC 
e_c uz_c idc_filt izc CIRC_REG MAXDCGAIN=MAXDCGAIN W_NOM=W_NOM KR=KR KP=KP WC=WC 

DrvUa drv_ua gnd uf_a uz_a vdc_mea blocked vcvs func=limit((VDC_NOM/2*v(vdc_mea) - v(uf_a) - v(uz_a))/(max(0.1,v(vdc_mea))*VDC_NOM),0,1)*(1-v(blocked))
DrvUb drv_ub gnd uf_b uz_b vdc_mea blocked vcvs func=limit((VDC_NOM/2*v(vdc_mea) - v(uf_b) - v(uz_b))/(max(0.1,v(vdc_mea))*VDC_NOM),0,1)*(1-v(blocked))
DrvUc drv_uc gnd uf_c uz_c vdc_mea blocked vcvs func=limit((VDC_NOM/2*v(vdc_mea) - v(uf_c) - v(uz_c))/(max(0.1,v(vdc_mea))*VDC_NOM),0,1)*(1-v(blocked))
DrvLa drv_la gnd uf_a uz_a vdc_mea blocked vcvs func=limit((VDC_NOM/2*v(vdc_mea) + v(uf_a) - v(uz_a))/(max(0.1,v(vdc_mea))*VDC_NOM),0,1)*(1-v(blocked))
DrvLb drv_lb gnd uf_b uz_b vdc_mea blocked vcvs func=limit((VDC_NOM/2*v(vdc_mea) + v(uf_b) - v(uz_b))/(max(0.1,v(vdc_mea))*VDC_NOM),0,1)*(1-v(blocked))
DrvLc drv_lc gnd uf_c uz_c vdc_mea blocked vcvs func=limit((VDC_NOM/2*v(vdc_mea) + v(uf_c) - v(uz_c))/(max(0.1,v(vdc_mea))*VDC_NOM),0,1)*(1-v(blocked))
ends

