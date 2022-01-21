function Es = Es_Vt(Vtrue, Hc)

%Compute Specific Energy given
%   True Airspeed (KTAS) and
%   Pressure Altitude (feet)

const = declare;

Es = Hc + (Vtrue*1.6878) .^ 2 / (2 * const.Gravity);