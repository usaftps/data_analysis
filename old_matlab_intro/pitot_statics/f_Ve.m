function f = f_Ve(Ve, Hc)

% determine f given
%    Equivalent Airspeed (KEAS) and
%    Pressure Altitude
%
% Written 13 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B

Vc = Vc_Ve(Ve, Hc);
i=1;
while i<=length(Vc)
if Vc(i) == 0
    f(i) = 1E+38;
else
    f(i) = Ve(i) / Vc(i);
end
i=i+1;
end