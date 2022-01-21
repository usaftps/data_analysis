function qcp=QcP(MorVc)

% if input = Mach
%   output = QcPa
%
% if input = Vc/asl
%   output = QcPsl
%
% Written 7 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B
const=declare; K3=const.K3;
id_lo=MorVc <=1;
id_hi=MorVc > 1;
qcp=zeros(size(MorVc));
if nnz(id_lo) > 0
    qcp(id_lo)=(1 + 0.2 * MorVc(id_lo).^ 2).^ 3.5 - 1;
end
if nnz(id_hi) > 0
    qcp(id_hi) = (K3 * MorVc(id_hi).^ 7) ./ (7 * MorVc(id_hi).^ 2 - 1).^2.5 - 1; % K3~166.921
end