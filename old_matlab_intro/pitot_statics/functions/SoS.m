function a=SoS(Ta)

% Compute Speed of Sound (knots) given ambient temperature, NOT total temp
%
%   a=SoS(Hc)
%
%  Ta - ambient temperature, C
%  a  - speed of sound in ft/sec^2
%
% Note: No instrument can measure ambient temperature, so you must convert
% the measured total temperature into ambient prior to this function
% 
% written by: Maj Time Jorris, TPS/CS, Feb 2009
%
% See also Tt_Ta

const=declare;
a = sqrt( (Ta+273.15)/const.Tsl )*const.asl;

end % function

