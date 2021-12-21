function M2=M2_M1(M1)

% Compute the Mach number on the subsonic side of a normal shock wave (M1)
%
%   M2=M2_M1(M1)
%
%  M1 - Mach in front of the shock
%  M2 - Mach behind the shock
%
% Equation (96) in NASA Technical Publications, USAF Test Pilot School

id_gt_1 = M1 > 1;
M2=M1; % The equation below is only good from M1 to M2, 
       % if a subsonic Mach is provide simply return it as the value
M2(id_gt_1) = sqrt((M1(id_gt_1) .^ 2 + 5) ./ (7 * M1(id_gt_1) .^ 2 - 1));
