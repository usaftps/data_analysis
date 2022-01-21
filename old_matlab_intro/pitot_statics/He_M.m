function He = He_M(M,energy)

% Find the Pressure Altitude of an Energy level given
%     Mach Number and
%     Specific Energy (feet)
%
% Assuming standard day temperature

const=declare;

HTry = energy;
TooMany = 100; %max number of iteration attempts
Tolerance = 0.00000001;
Try = 1;
x=1;

while x == 1
    
    He = energy - (Vt_M(M, Tstd(HTry))*1.6878) .^ 2 ./ (2 * const.Gravity);
    test = He - HTry;
    if abs(test) < Tolerance
        He_M = He;
        %MsgBox ("Number of Iterations = " & Try)
        x=0;
    elseif Try > TooMany Then
        msgbox('Max iterations Exceeded')
        He_M = Null;
        x=0;
    else
        HTry = He;
        Try = Try + 1;
    end
end

