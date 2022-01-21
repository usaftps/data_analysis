%% Readme
% Written 7 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B
%
%This program takes pressure altitude (Hc) and computes Vc if given Mach,
%or Mach if given Vc.  Mach is non-dimensional.
%Vc is calibrated airspeed in knots.  The units are only dependant on the
%speed of sound (asl) assigned in (Declarations).  Hc is in feet and
%is dependant on the equations in Delta.
%
%After looking through Herrington I finally figured out all of the required
%equations.  The iteration break point relies on Qc/Pa for Mach number
%and Qc/Psl for Vc; in both cases the value is:
%(1+0.2*(1.0))^3.5-1=0.892929158737854
%
%When computing Mach given Vc:
% Qc/Psl = f(Vc/asl)
% Qc/Pa = (Qc/Psl)/delta
% test the value of Qc/Pa
% use appropriate Mach=f(Qc/Pa) or Mach=f(Qc/Pa,M), the latter requires iteration
%
%When computing Vc when given Mach:
% Qc/Pa = f(Mach)
% Qc/Psl = (Qc/Pa) * delta
% test the value of Qc/Psl
% use appropriate Vc/asl=f(Qc/Psl) or Vc/asl=f(Qc/Psl,Vc/asl), the latter requires iteration
% Vc = (Vc / asl) * asl
%
%Fortunately the Qc/Pa and Qc/Psl have the same form, the output simply depends
%on whether given Mach or Vc/asl. The f(Qc/Pa,M) and f(Qc/Psl,Vc/asl) also have
%the same form, so the same iteration routine is called.
%
%The outcome is that for M>1, about 20 iteration gives Mach to the .00001
%and Vc to .001.  Just type:
%
%Primary Functions, the typical user would call
%=M_Vc(A1,B1) or =Vc_M(A1,B1) or =Delta(B1)
%
%M_Vc computes Mach given Vc
%Vc_M computes Vc given Mach
%
%Internal Functions, but can be called to debug
%or =QcP(A1)
%or =Iter8(QcP(A1)/Delta(B1)) to get Mach with A1=Vc
%or =Iter8(Delta(B1)*QcP(A1)) to get Vc with A1=Mach
%
%A1 would be Vc or Mach and B1 would be pressure altitude.
%
%Here are the equations referenced above.  The equation numbers
%with decimals are Herrington, the e1 and e2 are here for clarification.
%
%============== Subroutine QcP ==============
% qc/Psl=[1+0.2*(Vc/asl)^2]^3.5-1     {Vc <= asl}   (2.10)
%
% qc/Psl=166.921*(Vc/asl)^7
% -------------------------  -  1     {Vc > asl}    (2.11)
%    [7*(Vc/asl)^2-1]^2.5
%
% qc/Pa=(qc/Psl)*(Psl/Pa)=(qc/Psl)/delta            (e1)
%
% qc/Pa=[1+0.2*(M)^2]^3.5-1     {M <= 1}            (2.22)
%
% qc/Pa=166.921*(M)^7
% -------------------  -  1     {M > 1}             (2.24)
%  [7*(M)^2-1]^2.5
%
% qc/Psl=(qc/Pa)*(Pa/Psl)=(qc/Pa)*delta             (e2)
%
%============== Subroutine Mach ==============
% To solve for Mach: use 2.10 or 2.11 and then apply e1
%
% for qc/Pa <= 0.892929158737854:
% M=sqrt(5*[(qc/Pa+1)^(2/7)-1])  {solved from 2.22} (2.22*)
%
% for qc/Pa > 0.892929158737854:
% M=sqrt((qc/Pa+1)*(1/K4)*(1-1/(7*M^2))^2.5)        (2.25)
%
% K4 = 166.921/(7^2.5) = 1.287560
% 166.921 = (36/5)^3.5/6 = (7.2)^3.5/6
%
%============== Subroutine Vc ==============
% Use the same form as 2.22* and 2.25 for Vc/asl except using qc/Psl
%
% To solve for Vc: use 2.22 or 2.24 and then apply e2
%
% for qc/Psl <= 0.892929158737854:
% Vc/asl=sqrt(5*[(qc/Psl+1)^(2/7)-1])                      (like 2.22*)
%
% for qc/Psl > 0.892929158737854:
% Vc/asl=sqrt((qc/Psl+1)*(1/K4)*(1-1/(7*(Vc/asl)^2))^2.5)  (like 2.25)
%
% Vc=(Vc/asl)*asl
%
%============== Subroutine Iter8 ==============
% Equations (2.25) and (like 2.25) are in Iter8.
% The iteration is started with a guess of 1.0 and keeps looping.
% To add accuracy use a smaller Tolerance (it will get a little slower)
% To speed up the iteration use a larger Tolerance.
%
%============== Subroutine Delta ==============
%computes Pa/Psl using pressure altitude Hc in feet.
