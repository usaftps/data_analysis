function M = M_Vc(Vc, Hc)

% Compute Mach Number given Calibrated Airspeed and Pressure Altitude
% 
%   M = M_Vc(Vc,Hc)
% 
%     M     = Mach number
%     Vc    = calibrated airspeed (KCAS)
%     Hc    = pressure altitude (ft)
%     Delta = pressure ratio (Pa/Psl)
%     Qc    = dynamic pressure (lb/ft^2)
%     Pa    = ambient pressure (lb/ft^2)
%     Psl   = pressure at sea level  = 2116.22 lb/ft^2
%     asl   = speed of sound at sea level = 661.48 knots
% 
% Equation numbers refer to Herrington
% 
% If Vc <= asl
% 
%     Qc/Psl = (1 + 0.2 · (Vc/asl) ^ 2) ^ 3.5 - 1           (2.10)
% 
% If Vc  > asl
% 
%     Qc            K3 · (Vc/asl) ^ 7
%     ———    = ———————————————————————————— - 1             (2.11)
%     Psl      (7 · (Vc/asl) ^ 2 - 1) ^ 2.5
% 
% Qc/Pa  = (Qc/Psl) · (Psl/Pa) = (Qc/Psl) / Delta(Hc)
% 
% If Qc/Pa <= K1
% 
%     M = sqr( 5·[(Qc/Pa + 1) ^ (2 / 7) - 1] )  (solved from 2.22)
% 
% If Qc/Pa  > K1 then
% 
%             [( Qc     )   1    (          1     ) ^ 2.5]
%     M = sqr [( —— + 1 ) · —— · ( 1 -  ————————— )      ]  (2.25)
%             [( Pa     )   K4   (      7 · M ^ 2 )      ]
% 
% Notice that M is on both sides of the equation. First assume M=1.
% Then plug the new M back into the equation until the iteration converges.
% 
% K1 =  .892929158737854 which is Qc/Pa at M=1. See Vc_M
% K3 =  166.921580093168 which is ( (36/5) ^ 3.5 ) / 6
% K4 =  1.28755526120762 which is K3 / 7^2.5
% 
% Written 7 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B

% determine Mach Number given:
%   Calibrated Airspeed (KCAS),
%   Pressure Altitude (feet)
%
% The calibrated airspeed units are dictated
% by the units of Public Const asl in (Declarations)
% The units of Hc are dictated by the equations in Delta.
%


const=declare; asl=const.asl; VelPrec=const.VelPrec;
Vc = round(Vc*10^const.VelPrec)/10^const.VelPrec;

IsNegative = sign(Vc);
Vc=abs(Vc);

QcPsl = QcP(Vc / asl);
DelHc = Delta_Hc(Hc);

QcPa = QcPsl ./ DelHc;
% If DelHc < 1E-50 Then
%     QcPa = 1E+200
% Else
%     QcPa = QcPsl / Delta(Hc)
% End If

% QcP_Break is QcPa at Mach=1
M = zeros(size(Vc));
id_lo=QcPa<=const.QcP_Break;
id_hi=QcPa>const.QcP_Break;

if nnz(id_lo)>0
    M(id_lo) = sqrt(5 * ((QcPa(id_lo) + 1) .^ (2 / 7) - 1));
end
if nnz(id_hi)>0
    M(id_hi) = Iter8(QcPa(id_hi));
end
% Just to make sure the negative sign is not lost
M  = M  .* IsNegative;
M = round(M*10^const.MacPrec)/10^const.MacPrec;
end % function