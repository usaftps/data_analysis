function He = He_Vc(Vc_Vec, Energy_Vec)

% Find the Pressure Altitude of an Energy level given
%     Calibrated Airspeed (KCAS) and
%     Specific Energy (feet)
%
% Assuming standard day temperature

const=declare;
TooMany = 100; % max number of iteration attempts
%Tolerance = 0.00000001
Tolerance = 0.01;
He = zeros(size(Vc_Vec));

for i = 1:length(Vc_Vec)
    Vc = Vc_Vec(i);
    Energy = Energy_Vec(i);
    
HOld = -Energy;
%HTry = Energy - V_K2F(Vc) ^ 2 / (2 * Gravity)
%HDel = Energy
HNew = Energy;
Try = 1;    % number 1 attempt
NewEnergy = Energy;
while true
    Vt = Vt_Vc(Vc, Tstd(HNew), HNew);
    if abs(Vt) > sqrt(2E+307)
        He(i) = 1E+138;
        break
    end
    %M = M_Vc(Vc, HTry)
    NewEnergy = HNew + (Vt*1.6878) .^ 2 / (2 * const.Gravity);
    EDiff = Energy - NewEnergy;
    %He = Energy - V_K2F(Vt) ^ 2 / (2 * Gravity)
    if abs(EDiff) < Tolerance
        He(i) = HNew;
        %MsgBox ("Number of Iterations = " & Try)
        break
    elseif HNew < 0
        He(i) = -1;
        break
    elseif Try > TooMany
        %if HNew > 0 
            % Something may be wrong, Null value and give error
            %MsgBox ("Max iterations Exceeded in He_Vc")
            %He_Vc = Null
            He(i) = HNew; % Can usually get within a foot, good enough
            %He_Vc = EDiff
        %else
            % This was not intended to be correct for negative altitudes
            % Any number will do, so use the last iteration.
            %He_Vc = HNew
            %He_Vc = Null
        %end
        break
    else
        HDel = HNew - HOld;
        HOld = HNew;
        if EDiff > 0
            % Need more altitude
            HNew = HNew + 1 / 2 * abs(HDel);
        else
            HNew = HNew - 1 / 2 * abs(HDel);
        end
        Try = Try + 1;
    end
end
end
