// -----------------------------
//  AUXILIARY CIRCUITS:
//
//  P_REG
//  Q_REG
//  PI_REG
//  CIRC_REG
//  INNER_LOOP
//  FREQ_DEPENDENT_CABLE
//  PARALLEL_RL_CABLE
//  BLK_CTRL
// ----------------------------

// -----------------------------
//  P_REG
//  Active power regulation
//  d_axis outer loop
// ----------------------------

subckt P_REG idp_ref vdp vqp vdn vqn idp iqp idn iqn p_ref blocked
parameters KP=1 KI=1 MAX=1 MIN=1 CF=1

PMOD p_mod gnd vdp vdn vqp vqn idp idn iqp iqn vcvs \
	func= (v(vdp)*v(idp) + v(vqp)*v(iqp) + v(vdn)*v(idn) + v(vqn)*v(iqn))
PMEA    p_mea gnd p_mod gnd svcvs numer=[WN^2] denom=[WN^2,2*XI*WN,1] ic=0
ID_PI   idp_ref  p_ref p_mea blocked PI_REG  KP=KP KI=KI MAX=MAX MIN=MIN CF=CF

ends

// -----------------------------
//  Q_REG
//  Reactive power regulation
//  q_axis outer loop
// ----------------------------

subckt Q_REG iqp_ref vdp vqp vdn vqn idp iqp idn iqn q_ref blocked
parameters KP=1 KI=1 MAX=1 MIN=1 CF=1

QMOD q_mod gnd vdp vdn vqp vqn idp idn iqp iqn vcvs \
	func= (v(vqp)*v(idp) - v(vdp)*v(iqp) + v(vqn)*v(idn) - v(vdn)*v(iqn))

QMEA    q_mea gnd q_mod gnd svcvs numer=[WN^2] denom=[WN^2,2*XI*WN,1] ic=0
IQ_PI   iqp_ref  q_mea q_ref blocked PI_REG  KP=KP KI=KI MAX=MAX MIN=MIN CF=CF

ends

// -----------------------------
//  PI_REG
//  PI Regulator
//  (Anti Wind-up included)
// ----------------------------

subckt PI_REG out ref mea blocked
parameters KP=1 KI=1 MAX=1 MIN=-1 CF=1k

Err     err    gnd ref   mea blocked vcvs func= \
    ((v(blocked) > 0.5*VDIG) ? 0 : v(ref)) - v(mea)

Ecor  e_cor    gnd err    in   out  vcvs func=v(out,in)*CF+v(err)
Err_i err_i    gnd e_cor gnd       svcvs numer=[KI] denom=[0,1] maxdcgain=10 ic=0
In       in    gnd err err_i        vcvs func=KP*v(err)+v(err_i)
Out     out    gnd in               vcvs func=limit(v(in),MIN,MAX)

ends

// ----------------------------------------------------------
//  CIRC_REG
//  Circulating current control of converter
//  (Compatible with both balanced and unbalanced conditions)
// ----------------------------------------------------------

subckt CIRC_REG uz idc_ref iz
parameters MAXDCGAIN=1 W_NOM=2*pi*50 WC=4 KR=1k KP=10

uz1 uz1 gnd idc_ref iz svcvs \
		numer=[0,KR*WC*2] denom=[(2*W_NOM)^2,WC*2,1] maxdcgain=MAXDCGAIN ic=0
uz2 uz2 gnd idc_ref iz vcvs gain1=KP
uz  uz  gnd uz1 uz2 vcvs func=v(uz1) + v(uz2)

ends

// ----------------------------------------------------------
//  INNER_LOOP
//  Inner current loop of converter
//  (Compatible with both balanced and unbalanced conditions)
// ----------------------------------------------------------

subckt INNER_LOOP u_out i_mea v_mea i_comp i_ref omega 
parameters KP=1 KI=1 MAXGAIN=1 W=1 L=1 GAIN=1 

ERROR err   gnd i_ref i_mea 		 svcvs \
	        numer=[KI,KP] denom=[0,1] maxdcgain=MAXGAIN ic=0
UOUT  u_out gnd err   i_comp omega v_mea vcvs  \
		func = limit(v(v_mea) + v(err) + v(i_comp)*v(omega)*GAIN*L/W,-2,2)

;UOUT  u_out gnd err   i_comp omega v_mea vcvs  \
;		func = v(v_mea) + v(err) + v(i_comp)*v(omega)*GAIN*L/W

ends

// --------------------------------------------------------------
//  FREQ_DEPENDENT_CABLE
//  Frequency dependent model of cable with parallel r-l branches
// 
// The default parameters of the line refer to the monopolar cable
// of the DCS1 Cigrè power system (see Figure 6.24 of [2]).
// Cable data are given in Table 6.18 (2nd column) of [2].
//
// [2] - Guide for the development of models for HVDC converters in
// a HVDC grid. Working Group B4.57.
//
// --------------------------------------------------------------

subckt FREQ_DEPENDENT_CABLE in out egnd
parameters R1=2.1570 R2=0.1784 R3=0.2420 R4=0.0328 R5=0.0203
parameters L1=0.2879m L2=0.2814m L3=1.6m L4=4m L5=6.1m
parameters G=0.055u   C=0.2185u KM=100 IC=0

Line1 in   mid1 egnd PARALLEL_RL_CABLE \
	R1=R1 R2=R2 R3=R3 R4=R4 R5=R5 \ 
	L1=L1 L2=L2 L3=L3 L4=L4 L5=L5 \ 
	C=C   G=G   KM=KM/5 IC=IC
Line2 mid1 mid2 egnd PARALLEL_RL_CABLE \
	R1=R1 R2=R2 R3=R3 R4=R4 R5=R5 \ 
	L1=L1 L2=L2 L3=L3 L4=L4 L5=L5 \ 
	C=C   G=G   KM=KM/5  IC=IC
Line3 mid2 mid3 egnd PARALLEL_RL_CABLE \
	R1=R1 R2=R2 R3=R3 R4=R4 R5=R5 \ 
	L1=L1 L2=L2 L3=L3 L4=L4 L5=L5 \ 
	C=C   G=G   KM=KM/5 IC=IC
Line4 mid3 mid4 egnd PARALLEL_RL_CABLE \
	R1=R1 R2=R2 R3=R3 R4=R4 R5=R5 \ 
	L1=L1 L2=L2 L3=L3 L4=L4 L5=L5 \ 
	C=C   G=G   KM=KM/5 IC=IC
Line5 mid4 out egnd PARALLEL_RL_CABLE \
	R1=R1 R2=R2 R3=R3 R4=R4 R5=R5 \ 
	L1=L1 L2=L2 L3=L3 L4=L4 L5=L5 \ 
	C=C   G=G   KM=KM/5 IC=IC
ends

// --------------------------------------------------------------
//  PARALLEL_RL_CABLE
//  Cable with parallel r-l branches
// --------------------------------------------------------------

subckt PARALLEL_RL_CABLE t1 t2 egnd
parameters R1=R1 R2=R2 R3=R3 R4=R4 R5=R5
parameters L1=L1 L2=L2 L3=L3 L4=L4 L5=L5
parameters G=G  C=C  KM=KM IC=IC

gp1     t1     egnd   resistor        g=G/2*KM
rp1     t1     mid1   resistor        r=R1*KM
lp1     mid1   t2     inductor        l=L1*KM 
rp2     t1     mid2   resistor        r=R2*KM
lp2     mid2   t2     inductor        l=L2*KM
rp3     t1     mid3   resistor        r=R3*KM
lp3     mid3   t2     inductor        l=L3*KM
rp4     t1     mid4   resistor        r=R4*KM
lp4     mid4   t2     inductor        l=L4*KM
rp5     t1     mid5   resistor        r=R5*KM
lp5     mid5   t2     inductor        l=L5*KM
gp2     t2     egnd   resistor        g=G/2*KM

ends

// -----------------------------
//  BLK_CTRL
//  Blocking converter control
// ----------------------------
subckt BLK_CTRL acon on blocked vdp vqp idc_pos idc_neg

X ac_blocked gnd vsource vdc=0
Y dc_blocked gnd vsource vdc=0

BlkTot  blocked acon on ac_blocked dc_blocked BLKTOT 

ends


