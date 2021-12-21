function Vc=Vc_M(M, Hc)
% Compute Calibrated Airspeed given Mach Number and Pressure Altitude
% 
%   Vc=Vc_M(M, Hc)
% 
%     Vc    = calibrated airspeed (KCAS)
%     M     = Mach number
%     Hc    = pressure altitude (ft)
%     Delta = pressure ratio (Pa/Psl)
%     Qc    = dynamic pressure (lb/ft^2)
%     Pa    = ambient pressure (lb/ft^2)
%     Psl   = pressure at sea level  = 2116.22 lb/ft^2
%     asl   = speed of sound at sea level = 661.48 knots
% 
% Equation numbers refer to Herrington
% 
% If M <= 1
% 
%     Qc/Pa = (1 + 0.2 · M ^ 2) ^ 3.5 - 1           (2.22)
% 
% If M  > 1
% 
%     Qc           K3 · M ^ 7
%     ———   = ————————————————————— - 1             (2.24)
%     Pa      (7 · M ^ 2 - 1) ^ 2.5
% 
% Qc/Psl  = (Qc/Pa) · (Pa/Psl) = (Qc/Pa) · Delta(Hc)
% 
% If Qc/Psl <= K1
% 
%     Vc/asl = sqr( 5·[(Qc/Psl + 1) ^ (2 / 7) - 1] )  (solved from 2.10)
% 
% If Qc/Psl  > K1 then (same form as 2.25)
% 
%     Vc        [( Qc      )   1    (              1        ) ^ 2.5]
%     ——— = sqr [( ——— + 1 ) · —— · ( 1 -  ———————————————— )      ]
%     asl       [( Psl     )   K4   (      7 · (Vc/asl) ^ 2 )      ]
% 
% Notice that Vc/asl is on both sides of the equation. First assume Vc/asl=1.
% Then plug the new Vc/asl back into the equation until the iteration converges.
% 
% K1 =  .892929158737854 which is Qc/Psl at Vc/asl=1. See M_Vc
% K3 =  166.921580093168 which is ( (36/5) ^ 3.5 ) / 6
% K4 =  1.28755526120762 which is K3 / 7^2.5
% 
% Vc  = (Vc/asl) · asl

const=declare; % Mach to Vc and back should return same number, hence round
asl=const.asl;
QcP_Break=const.QcP_Break;
M = round(M*10^const.MacPrec)/10^const.MacPrec;

IsNegative = sign(M);
M = abs(M);

QcPsl = Delta_Hc(Hc) .* QcP(M); %Qc/Psl=(Pa/Psl)*(Qc/Pa)

id_lo=QcPsl <= QcP_Break;
id_hi=QcPsl >  QcP_Break;
Vc=zeros(size(M));
if nnz(id_lo) > 0
    Vc(id_lo) = asl * sqrt(5 * ((QcPsl(id_lo) + 1).^ (2 / 7) - 1));
end
if nnz(id_hi) > 0
    VcAsl = Iter8(QcPsl(id_hi));
    Vc(id_hi) = VcAsl * asl;
end
% Just to make sure the negative sign is not lost
Vc = Vc .* IsNegative;
Vc = round(Vc*10^const.VelPrec)/10^const.VelPrec;

end % function

