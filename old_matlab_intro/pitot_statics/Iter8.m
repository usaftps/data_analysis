function val=Iter8(QcP_)

% This is designed to iterate for (Vc/asl) or M, they follow
% the same iteration scheme so the variables are generic
%
% For iterating to find Mach Number:
%   Inter8 = M
%   QcP_   = QcPa
%
% For iterating to find Vc/asl:
%   Inter8 = Vc/asl
%   QcP_   = QcPsl
%
% Written 7 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B

TooMany     = 100; % max number of iteration attempts (30 is high)
Tolerance = 1e-10; % drive iteration to this accuracy
                                     % 1e-6 took about 9-12 iterations
                                     % 1e-8 took about 10-17 iterations
                                     % 1e-10 got up to 22
                                     
IOld = 2;   % This is the initial guess
Try  = 1;   % number 1 attempt
const=declare; K4=const.K4;
val=zeros(size(QcP_));
while true
    INew = sqrt((QcP_ + 1).*(1 / K4) .* (1 - 1 ./ (7 * IOld.^ 2)).^ 2.5); % Mach or Vc/asl greater than 1
    % K4 ~ 1.287560
    if all(abs(INew - IOld) < Tolerance)
        val = INew;        
        break
    elseif Try > TooMany
        warning('Max iterations Exceeded')
        val = NaN*INew; % should never see, but avoid a runaway loop
        break
    else
        IOld = INew;
        Try = Try + 1;
    end
end % while
% disp(['Number of iterations = ',num2str(Try)])
end % function