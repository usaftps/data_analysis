function rho=Dstd(Hc)

% Compute P_standard (lb/ft^2) at Hc (feet)
% 
%   rho=Dstd(Hc)
%
% Written 7 Oct 00 by:  Timothy R. Jorris
%                        TPS\00B
% Updated Feb 2009

% Dstd = Sigma(Tstd(Hc), Hc) * Dsl
rho=us76_ft(Hc);

end % function