function Ta = Ta_Tic(Tic, Mach, Kt)

    
% Kt is the recovery factor of the temperature probe.

% Always assume a normal shock before temperature probe

% I was confused whether more interest would be the ambient temperature
% in front of or behind the shock. Computes Tambient behind the shock.

% comment out this line to look at the Tambient infront of the shock
%Mach = M2_M1(Mach); % no effect if subsonic


Ta_C = T_C2K(Tic) ./ (1 + 0.2 .* Kt .* Mach .^ 2);
Ta = T_K2C(Ta_C);