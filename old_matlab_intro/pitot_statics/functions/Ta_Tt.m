function Ta = Ta_Tt(Tt, Mach)

% This is the same as Ta_Tic computation, however, assume Kt=1
% Kt is the recovery factor of the temperature probe.

% I was confused whether more interest would be the ambient temperature
% in front of or behind the shock. Computes Tambient behind the shock.

% comment out this line to look at the Tambient infront of the shock
%Mach = M2_M1(Mach); % no effect if subsonic

Ta = Ta_Tic(Tt, Mach, 1);