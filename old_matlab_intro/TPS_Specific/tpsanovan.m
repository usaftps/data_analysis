function [p,Model_tab,stats,terms]=tpsanovan(varargin)
%% Runs ANOVAN with TPS defaults, and additional Design Expert calculations
%
% p = tpsanovan(y,group)
% p = tpsanovan(y,group,param1,val1,param2,val2,...)
% [p,table] = tpsanovan(...)
% [p,table,stats] = tpsanovan(...)
% [p,table,stats,terms] = tpsanovan(...)
%
%  Example:
%  y=observation;
%  group=[g1,g2,g3];
%  model=eye(3);
%  cont=[1 2 3];
%  varnames={'A','B','C'};
%   [p,tab,stats,terms]=tpsanovan(y,group,...
%        'sstype',1,...
%         'model',model, ...
%         'continuous',cont, ....
%         'varnames',varnames);
% See also ANOVAN

%% Turn MATLAB's off, will turn ours on if requested
sstype='h'; % ET says 1
if nargin >=4 
    id = strmatch('sstype',varargin(3:2:end));
    if ~isempty(id) && isnumeric(varargin{3+(2*(id-1))+1})
%        warning('''sstype'' equal to ''h'' is most consistent with regression')
    end
end

default_args={ ...
        'sstype',sstype, ... % ET said so
        'alpha', 0.05};
        
if length(varargin) < 3
    [p,table,stats,terms]=anovan(varargin{:},...
        default_args{:}, ...
        'display','off');
else
    % put 'sstype' to 1 as TPS default, let user override so varargin is
    % last, display is last to trump user
    [p,table,stats,terms]=anovan(varargin{1:2},...
        default_args{:}, ...
        varargin{3:end},'display','off');
end
% anovan(y,group, ...
%     'alpha', 0.05, ...
%     'continuous',[], ... % [ 1 3 ] whichever are continuous
%     'display','off',...
%     'model','interaction',... % 'linear','interaction','full', [1 0 1]
%     'sstype',2, ... % ET said so
%     'varnames',varnames);

% fn=fieldnames(stats); for i=1:length(fn), disp(fn{i}), disp(stats.(fn{i})), end

%% Make our table look like DesignExpert's
SSE_df_MS=cell2mat(table(2:end-1,[2:3,5]));
Model_SSE_df=sum(SSE_df_MS(1:end-1,:));
MSM=Model_SSE_df(1)/Model_SSE_df(2);
MSE=SSE_df_MS(end,3);
F_MSM=MSM/MSE;
Mod_df=Model_SSE_df(2);
Err_df=SSE_df_MS(end,2);
p_MSM=1-fcdf(F_MSM,Mod_df,Err_df);

%% Table is missing first line
Model=[{'Model'},num2cell([Model_SSE_df(1:2),MSM,F_MSM,p_MSM])];
singular=cell2mat(table(2:end,4));
sing=0;
for i=2:(size(table,1)-2); % Don't care about Total or Error (-2)
    if singular(i-1) ~= 0
        table{i,1}=['#',table{i,1}];
        sing(i)=1;
    else
        table{i,1}=[' ',table{i,1}];
    end
end
table(:,4)=[]; % Singular? column
Model_tab=[table(1,:);Model;table(2:end,:)];
%% Add more to our table
std_dev=sqrt(MSE);
mean_y=mean(varargin{1});
Err_SS_df=cell2mat(table(end-1,2:3));
Tot_SS_df=cell2mat(table(end,2:3));
R2=1-Err_SS_df(1)/Tot_SS_df(1);
R2_adj=1-(Err_SS_df(1)/Err_SS_df(2))/(Tot_SS_df(1)/Tot_SS_df(2));
y=varargin{1};
X=ones(size(y));
Main=varargin{2};
    for i=1:size(stats.terms,1)
        Xi=ones(size(y));
        for j=1:size(stats.terms,2)
            if stats.terms(i,j)==1
                if iscell(Main(:,j))
                    if iscell(Main{:,j})
                        R2p=NaN; 'categoric';
                        PRESS=NaN;'categoric';
                        break
                    end
                     Xi=Xi.*Main{:,j}*stats.terms(i,j);
                else
                    Xi=Xi.*Main(:,j)*stats.terms(i,j);
                end
            end
        end
        X=[X,Xi];
        [R2p,PRESS]=r2predicted(y,X,Tot_SS_df(1));
    end
% else
%     X=NaN;
%     R2p=NaN;
%     PRESS=NaN;
% end

%% Anova: C.V. % (Coefficient of Variation)
% The coefficient of variation for this model. It is the error expressed as
% a percentage of the mean. It is computed as
% 
% 100 x (Std Dev)/(Mean)
CV=100*std_dev/mean_y;
PRESS=PRESS;
Pred_R2=R2p;
%% Anova: Adequate Precision
% Adequate precision is a measure of the range in predicted response
% relative to its associated error, in other words a signal to noise ratio.
% Its desired value is 4 or more.
% y_pred=X*pinv(X)*y;
% Adeq_Prec=(max(y_pred)-min(y_pred))/std(y_pred);
Adeq_Prec=' ';
Extra1={'Std. Dev';'Mean';'C.V. %';'PRESS'};
Extra2={'R-Squared';'Adj R-Squared';'Pred R-Squared';'Adeq Prec'};
blk=num2cell(char(' '*ones(size(Extra1,1),1)));
Extra=[Extra1,[num2cell(std_dev);num2cell(mean_y);num2cell(CV);num2cell(PRESS)],blk,blk,...
    Extra2,[num2cell(R2);num2cell(R2_adj);num2cell(Pred_R2);num2cell(Adeq_Prec)]];


% stats.rstats=regstats(y,X(:,2:end));

if length(varargin) > 3
    id=strfind(varargin(3:2:end),'display'); % did user ask for display
    for i=1:length(id)
        if ~isempty(id(i))
            
            pval=cell2mat(Model_tab(2:end-2,end));
            for i=1:length(pval)
                if pval(i) < 0.0001
                    Model_tab{i+1,end}='< 0.0001';
                end
            end
            Model_tab(end-1,1)={'Pure Error'};
            Model_tab(end,1)={'Cor Total'};
            digits=[-1  4 0 4  2  4];
            Model_tab= [...
                Model_tab;
                {'----','----','----','----','  ','  '};
                Extra];
            [tab,dig]=tab_dig(Model_tab,digits);
            
            % Create footer Information
            varg_name=varargin{3:2:end}; varg_val={varargin{4:2:end}};
            idss=strmatch('sstype',strvcat(varg_name),'exact'); % did user ask for 'sstype'
            if ~isempty(idss), sstype=varg_val{max(idss)}; end % take the last one if two
            if isequal(lower(sstype),'h')
                sstype = 2;
                dohier = true;
            else
                dohier = false;
            end
            switch(sstype)
                case 1,    cap = 'Sequential (Type I) sums of squares.';
                case 2, if dohier
                        cap = 'Hierarchical (modified Type II) sums of squares';
                    else
                        cap = 'Hierarchical (Type II) sums of squares.';
                    end
                otherwise, cap = 'Constrained (Type III) sums of squares.';
            end
            if (any(sing)), cap = [cap '  Terms marked with # are not full rank.']; end
            % Call ANOVA Table creator
            statdisptable(tab, ...
                'Boomer''s ANOVAN', 'Boomer''s ANOVAN',cap, dig);
            break
        end
    end
end

function [tab,dig]=tab_dig(tab,dig,table,stats,MSE)

function [R2p,PRESS]=r2predicted(y,X,SSt)
PRESS=0; % Predicted Sum Squared
for i=1:length(y)
   yi=y; yi(i)=[];
   Xi=X; Xi(i,:)=[];
   yhati=X(i,:)*pinv(Xi)*yi;
   PRESS=PRESS+(yhati-y(i))^2;   
end
R2p=1-PRESS/SSt;