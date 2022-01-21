function Hc = Hc_M(M,Vc)

% Compute the Pressure Altitude (ft) that satisfies a given:
%   Mach and
%   Calibrated Airspeed (KCAS)
%
%Written 21 Dec 00 by: Timothy R. Jorris
%                      TPS/00B

const=declare;

Qc_Pa = QcP(M);
Qc_Psl = QcP(Vc ./ const.asl);

%Pa/Psl = (Qc/Psl) / (Qc/Pa)
Pa = const.Psl .* Qc_Psl ./ Qc_Pa;

Hc = Hc_P(Pa);