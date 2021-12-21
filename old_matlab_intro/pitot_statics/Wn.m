function Wn = Wn(Zeta, AllData)

% See LogDec for help
% written by: Timothy R. Jorris, TPS/00B
%             18 Jan 01


PassArray = AllData
WdCalc = Wd(PassArray)
Wn = WdCalc / Sqr(1 - Zeta ^ 2)

