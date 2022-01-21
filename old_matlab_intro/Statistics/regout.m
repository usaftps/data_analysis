function [statsout,b,bint,r,rint,rstats,per,yhat,yhatci,yhatpi]=regout(y,X,varargin)

% REGOUT - Replicates Excel Regression Output
%
%  stats=regout(y,X)
%  [stats,b,bint,r,rint,rstats,pct]=regout(y,X,alpha,names,yname)
%  [stats,b,bint,r,rint,rstats,pct]=regout(y,X,alpha,names,yname,X0)
%
%  y                    - sampled data, i.e. observations
%  X                    - model, i.e. independent variable(s)
%                         -- do NOT include a column of ones, it will be
%                            created automatically in the first column
%  alpha                - (optional) default is 0.05, thus 95% confidence
%  xnames               - cell array to describe the factors in X
%  yname                - string or cell array containing name of y
%  stats                - stats structure, see REGSTATS
%  b,bint,r,rint,rstats - see REGRESS
%                         -- rstats is [R^2, F statistic, p-value, se^2]
%  pct                  - see PRCTILE 
%  X0                 - user defined X to plot model (not create it as in X)
%
% stats.X0          - model fit regressor matrix
% stats.yhatX0   - model at X0
% stats.yhatci     - confidence interval at yhatX0
% stats.yhatpi    - prediction interval at yhatXo  
%
%  Confidence Intervals: Part of the equation is based on the original
%  regressors, X. But, the confidence interval line can be computed at any
%  value of X0, or vector of X0. E.g. 5 samples within X could be used to
%  make a smooth confidence interval will 100 values within X0.
%
%  Example:
%       x=[1:9]';   % independent variable
%       rand('seed',69); % (optional) force same answer on next run
%       y=8+5*x-.02*x.^2+5*randn(size(x));  % known coefs are 8, 5, & -.02
%       % model is y = b(1) + b(2)·x + b(3)·x^2
%       X=[x, x.^2]; % matrix of independent variables
%       alpha=0.01;  % overrides the default of .05
%       xnames={'x','x^2'}; % for identification during output
%       yname ='y (x)';   % shows y is function of x
%       [stats,b,bint,r,rint,rstats,pct]=regout(y,X,alpha,xnames,yname)
%
%  Note: Run if no arguments to view the example. Also, detailed help is at
%  the bottom of this .m file.
%
% written by: Maj Tim Jorris
%             USAF TPS/CS, Jan 2009
%             v1: accepts yname and optional alpha
%
% See also REGRESS, REGSTATS, PRCTILE, and ROBUSTFIT


% Example - verifies mimicing Excel
if nargin==0 % Run example
    x=[1:9]';
    y=[
        13.3724035540059
        17.0243153135540
        23.4923043005531
        28.8860178742852
        32.5546389178481
        38.2719790941557
        43.0269204366833
        47.7283369505110
        52.8110945664814
        ];

    % method='linear';
    % method='quadratic'; 
    % X=[ones(size(x)), x, x.^2];
    X=[x, x.^2]; xnames={'x','x^2'}; yname={'y (x)'};
    alpha=0.01;
    % [stats,b,bint,r,rint,rstats,pct]=regout(y,X,alpha,xnames,yname); % ,alpha,names);
    [stats,b,bint,r,rint,rstats,pct]=regout(y,X,alpha,xnames,yname); 
    % y,X,stats,b,bint,r,rint,rstats,pct % output to screen   
    return    
end
% There are three possible inputs: alpha, names, yname
% Not all are required.
% Possible inputs are:
% alpha, xnames, yname, X0, and disp_output
% These all have unique types so order doesn't matter
alpha=0.05; dispit=true; yname='Y'; XY_true=[];
for i=1:length(varargin)
    temp=varargin{i};
    if isnumeric(temp) && length(temp)==1, alpha=temp;
    elseif iscell(temp), xnames=temp; 
    elseif isstr(temp), yname=temp;
    elseif isnumeric(temp), X0=temp;
    elseif islogical(temp), dispit=temp;
    end
end
%{
% this is the old, must be in order, method
if nargin < 2
    error('At least two inputs are required: regout(y,X)')
end
% Cannot get here with out at least two inputs
if nargin == 2 % No User Inputs, All Defaults
    alpha=0.05;
    % Do not define xnames or yname, exist will thus work later
elseif nargin == 3 %  alpha or xnames
    user_arg=varargin{1};
    if isnumeric(user_arg)
        alpha=user_arg;
    elseif iscell(user_arg)
        alpha=0.05;
        xnames=user_arg;
    else
        error('Expected input is a number for alpha, or a cell for xnames')
    end
elseif nargin==4 % (alpha, xnames) or (xnames,ynames)
    user1=varargin{1};
    user2=varargin{2};
    if isnumeric(user1) && iscell(user2)
        alpha =user1;
        xnames=user2;
    elseif iscell(user1) && ...
            (iscell(user2) || ischar(user2))
        alpha=0.05;
        xnames=user1;
        yname =user2;
    else
        error(['Expecting number and cell: (...,alpha,xnames)',...
            char(10),'Or cell and cell: (...,xnames, yname)'])
    end
elseif nargin>=5 % alpha, xnames, yname (and X0)
    user1=varargin{1};
    user2=varargin{2};
    user3=varargin{3};
    if isnumeric(user1)
        alpha=user1;
        if iscell(user2)
            xnames=user2;
            if iscell(user3) || ischar(user3)
                yname=user3;
            else
                error('Fifth argument should be a cell for yname')
            end
        else
            error('Forth argument should be cell of xnames')
        end
    else
        error('Third argument should be a number for alpha')
    end
end
if nargin>=6, X0=varargin{4}; end
if nargin>=7
    XY_true=varargin{5};
else
    XY_true=[];
end
if ~exist('alpha','var'), alpha=0.05; end
if ~exist('yname','var')
    yname='Y';
else
    if iscell(yname), yname=yname{1}; end
end
%}
stats=regstats(y,X);  % without ones since regstats adds for you
if nargout > 0, statsout=stats; end  % provide output if requested
% if nargin < 3, alpha=.05; end
X=[ones(size(X,1),1),X];  % Add column of ones for regress

% try
%     hj=jprintf(-1,' '); set(hj,'Text','')
% catch
% end
% This is just placing "Excel" labels on Matlab output
if dispit
zprintf('%s\n\n','SUMMARY OUTPUT')
                                zprintf('%s\n',char(ones(1,18)*'—'))  % 32
% zprintf(     'Regression Statistics         Computed From\n')
zprintf(     '%s \n','Regression Statistics')
                                zprintf('%s\n',char(ones(1,31)*'~'))   % 51
                                fmt1='%-18s %9.6g  %-20s\n'; fmt2='%-18s %9d  %-20s\n';
zprintf(fmt1,'Multiple R'        , sqrt(stats.rsquare), ' '); %sqrt(stats.rsquare)') 
zprintf(fmt1,'R Square'          , stats.rsquare      , ' '); %stats.rsquare')
zprintf(fmt1,'Adjusted R Square' , stats.adjrsquare   , ' '); %stats.adjrsquare')
zprintf(fmt1,'Standard Error'    , sqrt(stats.mse)    , ' '); %sqrt(stats.mse)') 
zprintf(fmt2,'Observations'      , length(y)          , ' '); %length(y)')
                                zprintf('%s\n\n',char(ones(1,18)*'—')) % 32

tab={...
    'Regression Statistics',' '; ...
    'Multiple R'        , sqrt(stats.rsquare); ...
    'R Square'          , stats.rsquare ; ...
    'Adjusted R Square' , stats.adjrsquare; ...
    'Standard Error'    , sqrt(stats.mse); ... 
    'Observations'      , length(y) ; ...
    };    
footer=' '; dig=[0 6];
statdisptable(tab, ...
                'Boomer''s Regression Statistics', 'Boomer''s Regression Statistics',...
                footer, dig);                                
% ANOVA
zprintf('%s\n','ANOVA'), fstat=stats.fstat;
                                zprintf('%s\n',char(ones(1,39)*'—'))
zprintf('%11s %4s %9s %9s %9s %15s\n', ...
    ' ','df','SS','MS','F','Significance F')
                                zprintf('%s\n',char(ones(1,63)*'~'))
zprintf('%-11s %4d %9.3f %9.4f %9.3f %15.2e\n',...
    'Regression',fstat.dfr,fstat.ssr,fstat.ssr/fstat.dfr,fstat.f,fstat.pval)
zprintf('%-11s %4d %9.4g %9.4g \n',...
    'Residual',fstat.dfe,fstat.sse,stats.mse)
zprintf('%-11s %4d %9.3f \n',...
    'Total',fstat.dfr+fstat.dfe,fstat.ssr+fstat.sse)
zprintf('%s\n\n',char(ones(1,39)*'—'))

tab={
    'ANOVA',' ',' ',' ',' ',' '; ...
    ' ','df','SS','MS','F','Significant F'; ...
    'Regression',fstat.dfr,fstat.ssr,fstat.ssr/fstat.dfr,fstat.f,fstat.pval; ...
    'Residual',fstat.dfe,fstat.sse,stats.mse,' ',' '; ...
    'Total',fstat.dfr+fstat.dfe,fstat.ssr+fstat.sse,' ',' ', ' '};
footer=' '; dig=[0 0 3 4 3 5];
statdisptable(tab, ...
                'Boomer''s ANOVA', 'Boomer''s ANOVA',...
                footer, dig);    
            
% Intecept (tstat) and corrcoef
end
[b,bint,r,rint,rstats] = regress(y,X,alpha);
if dispit
zprintf('%s\n',char(ones(1,48)*'—'))
zprintf('%-10s %9s %9s %10s %12s %10s %10s\n',...
    ' ','Coefs','Std Error','t Stat','P-value',['Lower ',num2str(100*(1-alpha)),'%'],['Upper ',num2str(100*(1-alpha)),'%'])
zprintf('%s\n',char(ones(1,77)*'~'))
tstat=stats.tstat;
user_provided=(exist('xnames','var') && iscell(xnames) && ~isempty(xnames{1}));
tab={
    'Regression Coefficients',' ',' ',' ',' ',' ',' '; ...
    ' ','Coefs','Std Error','t Stat','P-value',['Lower ',num2str(100*(1-alpha)),'%'],['Upper ',num2str(100*(1-alpha)),'%']; ...
    };

for i=1:length(tstat.t)
    if i==1, name='Intercept';
    elseif user_provided
        name=xnames{i-1};  % first one that doesn't include the ones        
    else
        if      i==1, name= 'Intercept';
        elseif  i==2, name= '1st Param';
        elseif  i==3, name= '2nd Param';   
        elseif  i==4, name= '3rd Param';       
        else        , name=[num2str(i-1),'th Param'];
        end   
        if i >= 2
            xnames{i-1}=name; % create for plotting later
        end
    end
    zprintf('%-10s %9.6f %9.6f %10.6f %12g %10.6f %10.6f\n', ...
        name,tstat.beta(i),tstat.se(i),tstat.t(i),tstat.pval(i),bint(i,:))
    tab=[tab;{name,tstat.beta(i),tstat.se(i),tstat.t(i),tstat.pval(i),bint(i,1),bint(i,2)}];        
end
zprintf('%s\n\n',char(ones(1,48)*'—'))

footer=' '; dig=[0 6 6 6 6 6 6];
statdisptable(tab, ...
                'Boomer''s Regression', 'Boomer''s Regression',...
                footer, dig);  
end
n=[1:size(X,1)]';
per=100*(n-.5)/length(n);
if dispit
%if nargout==0
    % RESIDUAL OUTPUT
    zprintf('%s\n','RESIDUAL OUTPUT'), yhat=stats.yhat; r=stats.r;
    standres=stats.standres; % This didn't match, hence the NaN
    zprintf('%s\n',char(ones(1,41)*'—'))
    zprintf('%12s %12s %10s    %-24s\n', ...
        'Observation','Predicted Y','Residuals','Std Residuals(almost Excel)')
    zprintf('%s\n',char(ones(1,67)*'~'))
    for i=1:length(yhat)
        zprintf('%12d %12.5f %10.6f    % -24.6f\n',i,yhat(i),r(i),standres(i))
    end
    zprintf('%s\n\n',char(ones(1,41)*'—'))
end
    % PROBABILITY OUTPUT
    yper=prctile(y,per);
if dispit
    zprintf('%s\n','PROBABILITY OUTPUT')
    zprintf('%s\n',char(ones(1,15)*'—'))
    zprintf('%11s %10s\n','Percentile',yname)
    zprintf('%s\n',char(ones(1,25)*'~'))
    for i=1:length(yhat)
        zprintf('%11.7g %10.5f\n',per(i),yper(i))
    end
    zprintf('%s\n\n',char(ones(1,15)*'—'))
end

% at least while publishing
%% Graphs
%
% Plot the residuals versus each of the independent variables 
if dispit
regtag='Tag_regout'; gridstate='on';
regfigs=findobj(0,'Type','figure','Tag',regtag);
delete(regfigs)  % delete the old ones
for i = 2:size(X,2)
    figure('Tag',regtag)
        hl=plot(X(:,i),stats.r,'bd'); set(hl,'MarkerFaceColor','blue')
        title([xnames{i-1},' Residual Plot'])
        xlabel(xnames{i-1}), ylabel('Residuals'), grid(gridstate) 
        xl=get(gca,'XLim'); xlim([min(xl)-.01*diff(xl), max(xl)+.01*diff(xl)])
    figure('Tag',regtag)
        hl=plot(X(:,i),y,'bd', ...
                X(:,i),stats.yhat,'rs'); set(hl(1),'MarkerFaceColor','blue')
        title([xnames{i-1},' Line Fit Plot'])
        xlabel(xnames{i-1}), ylabel(yname) , grid(gridstate)
        legend(yname,['Predicted ',yname],'Location','NW')
        xl=get(gca,'XLim'); xlim([min(xl)-.01*diff(xl), max(xl)+.01*diff(xl)])
end
%  figure('Tag',regtag)
%     hl=plot(per,yper,'bd'); set(hl,'MarkerFaceColor','blue')
%     title('Excel Format - Normal Probability Plot')
%     xlabel('Sample Percentile'), ylabel('Y'), grid(gridstate)
 figure('Tag',regtag)
    normplot(stats.r)
    % hl=plot(per,yper,'bd'); set(hl,'MarkerFaceColor','blue')
    % title('Matlab normplot - Normal Probability Plot')
    xlabel('Residuals'),  grid(gridstate)    
end
%% Confidence Intervals
% Graph yhat with confidence intervals
 if exist('X0','var')~=1
     % Ones already added to X, so remove
     X0=X(:,2:end);
%  else
%      % Add ones to user defined X0
%      n  =size(X0,1);
%      X0=[ones(n,1),X0];
 end

 
 if size(X,2)==2 % Simple [1, X-only]
    [yhat,yhatci,yhatpi]=confint_simple(y,X(:,2:end),stats,alpha,X0);
 else
    [yhat,yhatci,yhatpi]=confint_multiple(y,X(:,2:end),stats,alpha,X0);
 end 
 if nargout > 0, % provide output if requested
     statsout.X0=X0;
     statsout.yhatX0=yhat;
     statsout.yhatci=yhatci;
     statsout.yhatpi=yhatpi;
 end
 %
 if dispit
 %% LAGPLOT
      figure('Tag',regtag)
     lagplotn(stats.r)
 %%
  nopi=1;
  figure('Tag',regtag)
    % By now X has ones, but X0 does not
    hl=plot(X(:,2),y,'bd',...
        X0(:,1),yhat,'b-',X0(:,1),yhatci,'r--',...
        X0(:,1),yhatpi,'m-.');
    if ~isempty(XY_true)
        hold on
        ht=plot(XY_true(:,1), XY_true(:,2), 'k-','LineWidth',1);
        hold off
    end
    set(hl(1),'MarkerFaceColor','blue')
    set(hl(2),'Color',[0 .7 0])
    % hl=plot(per,yper,'bd'); set(hl,'MarkerFaceColor','blue')
    % title('Matlab normplot - Normal Probability Plot')
%     if length(xnames) ==2
%     	xlabel('X')
%     else
         xlabel(xnames{1})
%     end
    ylabel([yname,' and ',yname,'hat'])
    set(hl(2:end),'LineWidth',1)
    xl=get(gca,'XLim'); xlim([min(xl)-.01*diff(xl), max(xl)+.01*diff(xl)])
    % grid(gridstate)
    if isempty(XY_true)
    legend(hl([1:3,5]),'Observations (y)','Model (yhat)',...
        'Confidence Interval about yhat','Prediction Interval about yhat',...
        'Location','Best')
%         legend(hl([1:3]),'Observations (y)','Model (yhat)',...
%         'Confidence Interval about yhat', ...
%         'Location','Best')
    else
      legend([hl([1:3,5]);ht],'Observations (y)','Model (yhat)',...
        'Confidence Interval about yhat','Prediction Interval about yhat',...
        'Reference Model', ...
        'Location','Best')
    end
 end

%{
% if strcmpi(method,'linear'), n=2; else, n=4; end
n=2*(size(X,2)-1);
% figure % Brings it to front to see that something happen
subplot(n,1,1)
hl=plot(x,r,'bd'); grid on
title('X Residual Plot'), xlabel('X'), ylabel('Residuals')
set(hl,'MarkerFaceColor','blue')

if n > 2
    subplot(n,1,2)
    hl=plot(x.^2,r,'bd'); grid on
    title('X^2 Residual Plot'), xlabel('X^2'), ylabel('Residuals')
    set(hl,'MarkerFaceColor','blue')
end

subplot(n,1,(n/2+1))
hl=plot(x,y,'bd',x,yhat,'rs'); grid on
title('X Line Fit Plot'), xlabel('X'), ylabel('Y')
legend('Y','Predicted Y','Location','NW')

if n > 2
    subplot(n,1,(n/2+2))
    hl=plot(x.^2,y,'bd',x.^2,yhat,'rs'); grid on
    title('X^2 Line Fit Plot'), xlabel('X^2'), ylabel('Y')
    legend('Y','Predicted Y','Location','NW')
end

% Normal Probability Plot
% figure
hl=plot(per,yper,'bd');
title('Normal Probability Plot')
xlabel('Sample Percentile'), ylabel('Y')
set(hl,'MarkerFaceColor','blue')
%}

%% Expanded Comments
%
% the ***** >> are required commands or clarifying comments
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{
***** >> X=[ones(size(x), x, x.^2] % for model='quadratic'
***** >> stats=regstats(y,X,model); 
***** >> % all below are stats.(whatever's listed)
——————————————————
Regression Statistics
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Multiple R          sqrt(.rsquare)
R Square                 .rsquare
Adjusted R Square        .adjrsquare
Standard Error      sqrt(.mse)
Observations        length(y)
——————————————————

***** >> % all below are stats.fstat.(whatever's listed)
ANOVA 
———————————————————————————————————————
              df        SS        MS         F  Significance F
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Regression    .dfr      .ssr    .ssr/.dfr   .f   .pval
Residual      .dfe      .sse    .mse 
Total      .dfr+.dfe  .ssr+.sse 
———————————————————————————————————————

***** >> % all below are stats.tstat.(whatever's listed)
***** >> alpha    = 0.05;  % to get the 95% bounds
***** >> [b,bint] = regress(y,X,alpha);
————————————————————————————————————————————————
               Coefs Std Error     t Stat      P-value  Lower 95%  Upper 95%
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Intercept   .beta(1)  .se(1)      .t(1)       .pval(1)  bint(1,1)  bint(1,2)
X           .beta(2)  .se(2)      .t(2)       .pval(2)  bint(2,1)  bint(2,2)
X^2         .beta(3)  .se(3)      .t(3)       .pval(3)  bint(3,1)  bint(3,2)
————————————————————————————————————————————————

***** >> % all below are stats.(whatever's listed)
RESIDUAL OUTPUT
—————————————————————————————————————————
 Observation  Predicted Y  Residuals    Std Residuals(almost Excel)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
           1  .yhat(1)     .r(1)        .standres(1)               
           2  .yhat(2)     .r(2)        .standres(2)               
           3  .yhat(3)     .r(3)        .standres(3)
          ...  ...         ...           ...            
—————————————————————————————————————————

***** >> n=[1:length(x)]';
***** >> per=100*(n-.5)/length(n);
***** >> yper=prctile(y,per);
PROBABILITY OUTPUT
———————————————
 Percentile          Y
~~~~~~~~~~~~~~~~~~~~~~~~~
   per(1)      yper(1)
   per(2)      yper(2)
   per(3)      yper(3)
    ...          ...
———————————————
%}
function [yhat,ci,pi]=confint_simple(y,X,stats,alpha,X0)
% Simple Linear Regression
% 
% X regressors without a ones vector
% 
[n  ,p  ]=size(X); % nxp without a ones vector
[n0,p0]=size(X0); % nxp without a ones vector
X_1  =[ones(n,1)  ,X];   p  =p+1;
X0_1=[ones(n0,1),X0]; p0=p0+1;

coefs=stats.beta;
yhat_se=X_1  *coefs; % orginal yhat for sqrt error
yhat      =X0_1*coefs;
% CI Calculations
p=2;
tstat=tinv(1-alpha/2, n-p);
se=sqrt(sum((y-yhat_se).^2)/(n-p));
xbar=mean(X);
% Common term for CI and PI
num=n*(X0-xbar).^2;
den=n*sum(X.^2)-sum(X)^2;
% Confidence Interval
ci_half=tstat*se*sqrt(1/n+(X0-xbar).^2/(n-1)/(var(X)));
ci=[yhat-ci_half,yhat+ci_half];
%{
    % Verify Multiple Methods
    ci_half1=tstat*se*sqrt(1/n+num/den);
    for i=1:length(X0_1)
        ci_half3(i,1)=tstat*sqrt(se^2*X0_1(i,:)*(X_1'*X_1)^(-1)*X0_1(i,:)');
    end
    ci_half4=tstat*sqrt(se^2*diag(X0_1*(X_1'*X_1)^(-1)*X0_1'));
    ci_half5=NaN*tstat*sqrt(se^2*diag(X0*(X'*X)^(-1)*X0')); % X0 MUST have ones column
    check_0=max(abs([ci_half-ci_half1, ci_half-ci_half3, ci_half-ci_half4, ci_half-ci_half5]))
%}

% Prediction Interval
%pi_half=tstat*se*sqrt(1+1/n+num/den);
pi_half=tstat*se*sqrt(1+1/n+(X0-xbar).^2/(n-1)/(var(X)));
%pi_half4=tstat*sqrt(se^2*(1+diag(X0_1*(X_1'*X_1)^(-1)*X0_1')));
pi=[yhat-pi_half,yhat+pi_half];

function  [yhat,ci,pi]=confint_multiple(y,X,stats,alpha,X0)
% Multiple Linear Regression
[n  ,p  ]=size(X); % nxp without a ones vector
[n0,p0]=size(X0); % nxp without a ones vector
X_1  =[ones(n,1)  ,X];   p  =p+1;
X0_1=[ones(n0,1),X0]; p0=p0+1;

coefs=stats.beta;
yhat_se=X_1  *coefs; % orginal yhat for sqrt error
yhat      =X0_1*coefs;
% CI Calculations
tstat=tinv(1-alpha/2, n-p);
se=sqrt(sum((y-yhat_se).^2)/(n-p));
xbar=mean(X);

% Confidence Interval and Prediction Interval
ci_half=tstat*sqrt(se^2*diag(X0_1*(X_1'*X_1)^(-1)*X0_1'));
% ci_half2=NaN*ci_half;
% for i=1:n0
%     ci_half2(i)=tstat*sqrt(se^2*diag(X0_1(i,:)*(X_1'*X_1)^(-1)*X0_1(i,:)'));
% end
pi_half=tstat*sqrt(se^2*(1+diag(X0_1*(X_1'*X_1)^(-1)*X0_1')));
% Compute plus and minus direction
ci=[yhat-ci_half,yhat+ci_half];
pi=[yhat-pi_half,yhat+pi_half];
1;
function zprintf(varargin)

%try
%     hj=jprintf(1,varargin{:});
%     % mf = uisetfont(cf);            %mf is a struct of modified font
%     % f = java.awt.Font(mf.FontName, style, mf.FontSize);
%     mf.FontName='Monospaced';
%     mf.FontWeight='normal';
%     mf.FontAngle='normal';
%     mf.FontSize=18;
%     mf.FontUnits='points';
%     style = java.awt.Font.BOLD;
%     f = java.awt.Font(mf.FontName, style, mf.FontSize);
%     %htext=get(hj,'Text');
%     hj.setFont(f);
%     %hjf=get(hj,'Font');
%     %set(hjf,'Name','Monospaced','Size',16)
%     % set(hj,'FontName','Monospace','FontSize',16)
% % catch
     fprintf(varargin{:})
% end

function lagplotn(resids, n)
%LAGPLOTN Produce a nth lag plot of residuals and show a trend line
%
%       lagplotn(residuals)
%       lagplotn(residuals,n)
%
%   residuals - row or column vector of residuals
%   n         - (optional) plot i versus i+n.  Default is 1 if not provided
% 
% Example:
%   a   = -5; b = 5;                % min to max
%   res = a + (b-a) * rand(101,1);  % residuals with no trend
%   lagplotn(res,2)
%   
% written by: Maj Tim Jorris, TPS/CS, July 2008
%
% See also RESID, COMPARE, and PREDICT

%% Run example if no arguments are given
if nargin==0 % run the example
    a   = -5; b = 5;  % min max
    res = a + (b-a) * rand(100,1);  % residuals with no trend    
    lagplotn(res,2)
    return
end
%% Default value for n
if nargin < 2, n=1; end 

%% Determine the linear trend
len=length(resids);
vec1=resids(1:(len-n));  % keeps number of points - n
vec2=resids(1+n:len);    
% id=[1:(len-n);1+n:len]'; id(1:10,:)
% vec1=resids(1:n:(len-n));  % divids points by n
% vec2=resids(n+1:n:len);
% id=[1:n:(len-n);n+1:n:len]'; id % id(1:5,:)
if length(vec1) >= 2 
    coef=polyfit(vec1,vec2,1); % linear fit
    xlin=linspace(min(vec1),max(vec1),1000);
    ylin=polyval(coef,xlin);  % pretty line values
    yR2 =polyval(coef,vec1);  % same size as original data
    R2=1-sum((yR2-vec2).^2)/sum(vec2.^2); % Excel R2
else
    xlin=NaN; ylin=NaN; R2=NaN; coef=[NaN, NaN];
end
hl=plot(vec1,vec2,'ro',xlin,ylin,'b-',NaN,NaN,'rx'); % NaN is for legend spacing
set(hl(3),'Marker','none')
xlabel('residual ( i )'), ylabel(sprintf('residual ( i + %d )',n))
title(sprintf('Lag Plot: n = %d',n))
hleg=legend(hl(2),...
    sprintf('y  = %.4f x + %.4f; R^2 = %.4f',coef(1),coef(2),R2), ...
    'Location','N');
set(hleg,'Color','None','Box','off') % max legend transparent

% JPRINTF general print utility.
% function h = JPRINTF(dev,fmt,p1,p2,...) is a general replacement
% for the built-in fprintf function.  In addition to printing to a
% file or the command window, JPRINTF can print formatted output to
% one or more text windows.  The text windows resemble the command
% window and can be independantly positioned, editted, and printed.
%
% Parameter dev is a device specifier which controls the destination
% of the output:
%    dev = 1      -- standard output
%    dev = 2      -- standard error
%    dev = fid    -- open file with handle = fid
%    dev = -n     -- text window n (note the minus sign!)
%
% The optional return argument h contains a handle to the Java TextArea
% object.  Use get(h), set(h), inspect(h), or methods(h) to access its
% properties and methods.  To retrive the complete text string, use
% h.getText or get(h,'Text').  Furthermore, getappdata(0) will return a
% structure with fields containing the java TextArea objects for all open 
% windows.
%
% Example:
%   >> jprintf(-1,'pi is approximately = %6.4f\n',pi)
%   >> jprintf(-7,'HELLO WORLD\n')
%   >> jprintf(-1,'Added Text')
% creates two text windows.  The first window, named "Java Box 1", contains
% the string "pi is approximately = 3.1416" on the first line and "Added Text"
% on the second line. The second window, named "Java Box 7", contains the
% string "HELLO WORLD".
%
% Use the pull-down menus to perform these functions:
%     File: open, save, save as, page setup, print, close
%     Edit: cut, copy, paste, select all, clear all
%     Format: font, foreground color, background color, wrap (on/off)
%
% JPRINTF is programmed entirely in Matlab and Java.  It uses the Java
% classes supplied with Matlab R14, including Wildcrest J2PrinterWorks for
% implementation of all hardcopy printer functions.  Usage of Wildcrest is
% unlicensed and for evaluation purposes only.  All printouts will have a
% mandatory header/footer marked "EVALUATION USE ONLY" and an extra nag
% page at the end of the printjob.  The author cannot delete these!
%
% See MYDISPLAY.M for an S-function wrapper for use in Simulink.
% JPRINTF supercedes GPRINTF which will no longer be maintained.
% Help FPRINTF for more information.
%
% Version 1.0
% July 2004
% Mark W. Brown
% mwbrown@ieee.org

% Tested under Matlab Version 7.0 (R14), Java 1.4.2, and Windows 2000 SP2.

function hrtn = jprintf(varargin)

persistent JavaBoxPos

% User has to input something:
if isempty(varargin);
  error('Not enough input arguments.')
  return
end

% Get device (dev) and format (fmt) specifiers
% and create a properly formatted string:
if isnumeric(varargin{1}) % first argument is a device
  if length(varargin) < 2
    error('No format string.');
    return
  end
  dev = varargin{1};
  fmt = varargin{2};
  str = sprintf(varargin{2:end});
else % first argument is a format string
  dev = 1;
  fmt = varargin{1};
  str = sprintf(varargin{:});
end

% If device specifier is positive number,
% then do a regular built-in fprintf:
if dev > 0
  fprintf(dev,str);

% Else if its a negative number, then
% we must create or update a java window:
elseif dev < 0
  
  % Get the name of this java window:
  dev = abs(dev);
  namestr = ['JavaBox',num2str(dev)];
  
  % See if the java window already exists:
  text = getappdata(0,namestr);
  if isempty(text)
  
    % The window doesn't exist, so we need to create it:
    import java.awt.*
		import javax.swing.*
    import com.wildcrest.j2printerworks.*
		
		% Create frame object:
		frame = javax.swing.JFrame(['Java Box ',num2str(dev)]);
		frame.setSize(400,300)

    % Stagger position so frames don't overlap.  Restart
    % if the new frame will be off the screen.
    ScreenDim = get(0,'ScreenSize');
    if isempty(JavaBoxPos)
      JavaBoxPos = [0 0];
    else
      JavaBoxPos = JavaBoxPos + [30 30];
      if any(JavaBoxPos+[400 300] > ScreenDim(3:4))
        JavaBoxPos = [0 0];
      end
    end
    frame.setLocation(JavaBoxPos(1),JavaBoxPos(2));
    
		% Create text object:
		text = javax.swing.JTextArea;
    
    % Create printer:
    if version('-release') > 13
      printer = J2Printer;
      textPrinter = J2TextPrinter(text);
    end

		% Create scroller object with text:
		scroller = javax.swing.JScrollPane(text);
		
		% Create menu bar:
		mymenu = javax.swing.JMenuBar;
		
		% Create FILE menu:
		menu1 = javax.swing.JMenu('File');
		mymenu.add(menu1);
		
		% Add items under FILE menu:
		menuitem1a = javax.swing.JMenuItem('Open...');
		set(menuitem1a,'ActionPerformedCallback',{@DoOpenFile, menuitem1a})
    set(menuitem1a,'UserData',text);
		menu1.add(menuitem1a);
	
		menuitem1b = javax.swing.JMenuItem('Save');
		set(menuitem1b,'ActionPerformedCallback',{@DoSaveFile, menuitem1b})
    set(menuitem1b,'UserData',text);
		menu1.add(menuitem1b);
		
		menuitem1c = javax.swing.JMenuItem('Save As...');
		set(menuitem1c,'ActionPerformedCallback',{@DoSaveFileAs, menuitem1c})
    set(menuitem1c,'UserData',text);
		menu1.add(menuitem1c);
		
		if version('-release') > 13
      menu1.addSeparator;
      menuitem1e = javax.swing.JMenuItem('Page Setup...');
      set(menuitem1e,'ActionPerformedCallback',{@DoPageSetup, menuitem1e, printer})
      menu1.add(menuitem1e);

      menuitem1g = javax.swing.JMenuItem('Print...');
      set(menuitem1g,'ActionPerformedCallback',{@DoPrint, menuitem1g, printer, textPrinter})
      menu1.add(menuitem1g);
    end
    
    menu1.addSeparator;
		menuitem1d = javax.swing.JMenuItem('Close');
		set(menuitem1d,'ActionPerformedCallback',{@DoClose, menuitem1d, frame})
		menu1.add(menuitem1d);
		
		% Create EDIT menu:
		menu2 = javax.swing.JMenu('Edit');
		mymenu.add(menu2);
		
		% Add items under EDIT menu:
		menuitem2a = javax.swing.JMenuItem('Cut');
		set(menuitem2a,'ActionPerformedCallback',{@DoCut, menuitem2a})
    set(menuitem2a,'UserData',text);
		menu2.add(menuitem2a);
		
		menuitem2b = javax.swing.JMenuItem('Copy');
		set(menuitem2b,'ActionPerformedCallback',{@DoCopy, menuitem2b})
    set(menuitem2b,'UserData',text);
		menu2.add(menuitem2b);
		
		menuitem2c = javax.swing.JMenuItem('Paste');
		set(menuitem2c,'ActionPerformedCallback',{@DoPaste, menuitem2c})
    set(menuitem2c,'UserData',text);
		menu2.add(menuitem2c);
    
    menu2.addSeparator;
    menuitem2e = javax.swing.JMenuItem('Select All');
		set(menuitem2e,'ActionPerformedCallback',{@DoSelectAll, menuitem2e})
    set(menuitem2e,'UserData',text);
		menu2.add(menuitem2e);
		
		menu2.addSeparator;
		menuitem2d = javax.swing.JMenuItem('Clear All');
		set(menuitem2d,'ActionPerformedCallback',{@DoClearAll, menuitem2d})
    set(menuitem2d,'UserData',text);
		menu2.add(menuitem2d);
		
		% Create FORMAT menu:
		menu3 = javax.swing.JMenu('Format');
		mymenu.add(menu3);
		
		% Add items under FORMAT menu:
		menuitem3a = javax.swing.JMenuItem('Font...');
		set(menuitem3a,'ActionPerformedCallback',{@DoFont, menuitem3a})
    set(menuitem3a,'UserData',text);
		menu3.add(menuitem3a);

		menu3.addSeparator;
		menuitem3b = javax.swing.JMenuItem('Foreground Color...');
		set(menuitem3b,'ActionPerformedCallback',{@DoForeColor, menuitem3b})
    set(menuitem3b,'UserData',text);
		menu3.add(menuitem3b);
		
		menuitem3c = javax.swing.JMenuItem('Background Color...');
		set(menuitem3c,'ActionPerformedCallback',{@DoBackColor, menuitem3c})
    set(menuitem3c,'UserData',text);
		menu3.add(menuitem3c);
		
		menu3.addSeparator;
		menuitem3g = javax.swing.JCheckBoxMenuItem('Word Wrap');
		set(menuitem3g,'ItemStateChangedCallback',{@DoWordWrap, menuitem3g});
    set(menuitem3g,'UserData',text);
		menu3.add(menuitem3g);
		
	  % Create HELP menu:
		menu4 = javax.swing.JMenu('Help');
		mymenu.add(menu4);
		
		% Add items under FORMAT menu:
		menuitem4a = javax.swing.JMenuItem('JPRINTF Help');
		set(menuitem4a,'ActionPerformedCallback',{@DoHelpUsing, menuitem4a})
		menu4.add(menuitem4a);
    
		menu4.addSeparator;
		menuitem4b = javax.swing.JMenuItem('About JPRINTF');
		set(menuitem4b,'ActionPerformedCallback',{@DoHelpAbout, menuitem4b})
		menu4.add(menuitem4b);

    % Add the widgets to the frame and make visible:
		frame.getContentPane.add(BorderLayout.CENTER,scroller);
		frame.getContentPane.add(BorderLayout.NORTH,mymenu);
		frame.show
    
    % Add the input text to the java TextArea:
    text.append(str);
    
    % Enable some handy features:
    if version('-release') > 13
      set(text,'dragEnabled','on');
    end
    
    % Store the text object in appdata so we can find it later.
    % Also define a callback to remove appdata when the box is closed.
    set(text,'name',namestr);
    set(text,'AncestorRemovedCallback','rmappdata(0,get(gcbo,''name''))');
    setappdata(0,namestr,text);

  else
    
    % Add the input text to the java TextArea:
    text.append(str);

  end
end

% Return an optional java TextArea object.
if nargout 
    if dev < 0
        hrtn = text;
    else
        hrtn=NaN;
    end
end

return

% Read a text file into the window.  The filename
% is NOT remembered, so if you try to save later,
% you will have to supply a filename.
function DoOpenFile(a,b,obj)
  [fname, fpath] = uigetfile('*.*');
  if fpath == 0; return; end
  filespec = fullfile(fpath,fname);
  fid = fopen(filespec,'r');
  ftext = fscanf(fid,'%c');
  fclose(fid);
  htext = get(obj,'UserData');
  set(htext,'Text',ftext);
return

% Write the text to a file.  If a previous
% SAVEAS function was executed, the same
% filename will be used.
function DoSaveFile(a,b,obj)
  htext = get(obj,'UserData');
  fspec = get(htext,'UserData');
  if isempty(fspec);
    DoSaveFileAs(a,b,obj);
  else
    ttext = get(htext,'Text');
    fid = fopen(fspec,'w');
    fprintf(fid,'%s',ttext);
    fclose(fid);
  end
return

% Write the text to a file.  The supplied filename
% is remembered for all subsequent SAVE operations.
function DoSaveFileAs(a,b,obj)
  htext = get(obj,'UserData');
  ttext = get(htext,'Text');
  [fname, fpath] = uiputfile('*.txt','Saving text to...');
  if isstr(fname)
    fspec = fullfile(fpath,fname);
    set(htext,'UserData',fspec);
    fid = fopen(fspec,'w');
    fprintf(fid,'%s',ttext);
    fclose(fid);
  end
return

% Set up page for printing:
function DoPageSetup(a,b,obj,printer)
  printer.showPageSetupDialog;
return

% Print hardcopy to a printer:
function DoPrint(a,b,obj,printer,textPrinter)
  printer.print(textPrinter);
return

% Close the window:
function DoClose(a,b,obj,frame)
  frame.dispose;
return

% Cut selected text.
function DoCut(a,b,obj)
  htext = get(obj,'UserData');
  htext.cut;
  htext.updateUI
return

% Copy selected text to a buffer:
function DoCopy(a,b,obj)
  htext = get(obj,'UserData');
  htext.copy;
return

% Paste the buffered text at cursor location:
function DoPaste(a,b,obj)
  htext = get(obj,'UserData');
  htext.paste;
return

% Select all the text in the window:
function DoSelectAll(a,b,obj)
  htext = get(obj,'UserData');
  htext.selectAll;
return

% Clear all text from the window:
function DoClearAll(a,b,obj)
  htext = get(obj,'UserData');
  set(htext,'Text','');
return

% Change the font of the displayed text.  Note
% that Java cannot do simultaneous Bold and Italic.
% If you select both, you will only get Bold.
function DoFont(a,b,obj)
  htext = get(obj,'UserData');
  hf = get(htext,'Font');
  cf.FontName = get(hf,'Name');  %cf is a struct of current font
  cf.FontUnits = 'points';
  cf.FontSize = get(hf,'Size');
  if strcmp(get(hf,'Bold'),'on')
    cf.FontWeight = 'bold';
  else
    cf.FontWeight = 'normal';
  end
  if strcmp(get(hf,'Italic'),'on')
    cf.FontAngle = 'italic';
  else
    cf.FontAngle = 'normal';
  end
  mf = uisetfont(cf);            %mf is a struct of modified font
  if isstruct(mf)
    style = java.awt.Font.PLAIN;
    if strcmp(mf.FontWeight,'bold')
      style = java.awt.Font.BOLD;
    elseif strcmp(mf.FontAngle,'italic')
      style = java.awt.Font.ITALIC;
    end
    f = java.awt.Font(mf.FontName, style, mf.FontSize);
    htext.setFont(f);
  end
return

% Change the font color:
function DoForeColor(a,b,obj)
  htext = get(obj,'UserData');
  oldrgb = get(htext,'Foreground');
  newrgb = uisetcolor(oldrgb);
  set(htext,'Foreground',newrgb);
return

% Change the background color:
function DoBackColor(a,b,obj)
  htext = get(obj,'UserData');
  oldrgb = get(htext,'Background');
  newrgb = uisetcolor(oldrgb);
  set(htext,'Background',newrgb);
return

% Toggle word wrap:
function DoWordWrap(a,b,obj)
  htext = get(obj,'UserData');
  state = get(obj,'State');
  if strcmp(state,'off')
    set(htext,'LineWrap','off');
  else
    set(htext,'LineWrap','on');
    set(htext,'WrapStyleWord','on');
  end
return

% Display help:
function DoHelpUsing(a,b,obj)
  helpwin jprintf;
return

% Display about:
function DoHelpAbout(a,b,obj)
  helpdlg({'Version 1.0','July 2004','Mark W. Brown','mwbrown@ieee.org'},'About JPRINTF');
return