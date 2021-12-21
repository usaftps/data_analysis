function Vt = Vt_M(M,Ta)
% Compute True Airspeed given Mach Number and Ambient Temperature
% 
% Vt_M(M,Ta)
% 
%     Vt_M = true airspeed (KTAS)
%     M    = Mach number
%     Ta   = ambient temperature (°C)
%     a    = speed of sound (knots)
%
% Note: If you only have altitude, use Tstd(Hc) to get standard day Ta
% 
% Vt = M · a = M · SoS(Ta)

Vt = M .* SoS(Ta);
