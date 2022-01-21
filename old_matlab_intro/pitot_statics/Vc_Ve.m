function Vc = Vc_Ve(Ve, Hc)

% determine Calibrated Airspeed (KCAS) given:
%   Equivalent Airspeed (KEAS),
%   Pressure Altitude (feet)
%
% Written 9 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B
%
% Ve is standard day temperature

%Vtrue = Ve / Sqr(Sigma(Tstd(Hc), Hc))
%M = Vtrue / SoS(Tstd(Hc))

M = M_Ve(Ve, Hc);
Vc = Vc_M(M, Hc);