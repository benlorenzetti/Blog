clear;
clc;
run('econdata.m');

home_apr = s2m_data(import_fred_csv('Data/MORTGAGE30US.csv'));   % percent apr
deficit = s2m_data(import_fred_csv('Data/FYFSD.csv')); % millions per year
deficit(2,:) = -1*deficit(2,:);
debt = s2m_data(import_fred_csv('Data/GFDEBTN.csv'));  % millions
remit = s2m_data(import_fred_csv('Data/RESPPLLOPNWW.csv')); % millions per week
remit = moving_ave(remit, 12);
remit(2,:) = 52*remit(2,:);                              % -> millions per year 
int_pay = s2m_data(import_fred_csv('Data/A091RC1Q027SBEA.csv')); % billions per year 
int_pay(2,:) = int_pay(2,:) * 1000;                  % -> millions per year
int_rt = s2m_data(import_fred_csv('Data/FEDFUNDS.csv'));  % pct (annual)
tip_yield = s2m_data(import_fred_csv('Data/DFII10.csv')); % pct (annual)
price_index = s2m_data(import_fred_csv('Data/CPIAUCSL.csv'));
cpi = differ(moving_ave(price_index, 12));
cpi(2,:) = ((1+cpi(2,:)).^12 - 1)*100;
pop = differ(moving_ave(s2m_data(import_fred_csv('Data/POPTHM.csv')), 12));
pop(2,:) = ((1+pop(2,:)).^12 - 1)*100;
recess = import_fred_csv('Data/JHDUSRGDPBR.csv');  % 0 or 1
unrate = s2m_data(import_fred_csv('Data/UNRATE.csv'));
emrate = unrate;
emrate(2,:) = 100 - unrate(2,:);
trade = moving_ave(s2m_data(import_fred_csv('Data/BOPGSTB.csv')), 12); % millions per month
trade(2,:) = 12*trade(2,:);
curaccount_trade = s2m_data(import_fred_csv('Data/BOPBCA.csv')); % billions per quarter
curaccount_trade(2,:) = (4000)*curaccount_trade(2,:);
truncation_point = lookup(curaccount_trade(1,:), trade(1,1));
curaccount_trade(:,truncation_point:size(curaccount_trade)(2)) = [];
trade_splice = curaccount_trade;
trade_splice = [trade_splice, trade];

trade_tot(1,:) = trade_splice(1,:);
trade_tot(2,1) = trade_splice(2,1);
i = 1;
do 
  i = i + 1;
  trade_tot(2,i) = trade_tot(2,i-1) + trade_splice(2,i)/12;
until(i == size(trade_splice)(2))

med_wage = s2m_data(import_fred_csv('Data/LES1252881600Q.csv'));
wage_change = differ(moving_ave(med_wage, 24));
wage_change(2,:) = ((1+wage_change(2,:)).^12 - 1)*100;
rgdp = s2m_data(import_fred_csv('Data/GDPC1.csv'));
drgdp = differ(moving_ave(rgdp, 24));
drgdp(2,:) = ((1+drgdp(2,:)).^12 - 1)*100;

walcl = s2m_data(import_fred_csv('Data/WALCL.csv')); % millions
totra = s2m_data(import_fred_csv('Data/TOTRA.csv')); % millions
wm2ns = s2m_data(import_fred_csv('Data/WM2NS.csv')); % billions

ID = []; % indirect deficit (millions per year)
RD = []; % real deficit
RDINF = []; % real deficit inflation pct
INTINF = []; % int payment inflation pct
INFNET = [];
PH1 = [];
PH2 = [];
R1 = [];
R2 = [];

start_yr = 1950;
end_yr = 2023;

def(1,:) = 12*start_yr-11 : 12*end_yr;
def(2,:) = 0*ones(1, 12*(end_yr - start_yr + 1));
remit = [];
remit(1,:) = 12*start_yr-11 : 12*end_yr;
remit(2,:) = 0*ones(1, 12*(end_yr - start_yr + 1));

m = (start_yr-1) * 12;
while(m < end_yr * 12)
  m = m + 1;
  % Indirect Deficit
  if(isin(m, int_rng(oc_rng(deficit), oc_rng(remit))))
    deficit_m = deficit(2,lookup(deficit(1,:), m));
    remit_m = remit(2, lookup(remit(1,:), m));
    ind_deficit_m = deficit_m + remit_m;
    ID = [ID, [m; ind_deficit_m]];
    % Real Deficit 
    if(isin(m, oc_rng(int_pay)))
      int_paym = int_pay(2, lookup(int_pay(1,:), m));
      real_deficit_m = ind_deficit_m - int_paym;
      RD = [RD, [m; real_deficit_m]];
      % Real Deficit Inflation
      if(isin(m, oc_rng(debt)))
        debtm = debt(2, lookup(debt(1,:), m));
        real_def_infm = 100 * (real_deficit_m) / debtm;
        RDINF = [RDINF, [m; real_def_infm]];
      endif
    endif
  endif
  % Interest Inflation
  if(isin(m, int_rng(oc_rng(int_pay), oc_rng(debt))))
    int_paym = int_pay(2, lookup(int_pay(1,:), m));
    debtm = debt(2, lookup(debt(1,:), m));
    int_infm = 100 * int_paym / debtm;
    INTINF = [INTINF, [m; int_infm]];
  endif
  % Net Expected Inflation
  if(isin(m, int_rng(int_rng(oc_rng(RDINF), oc_rng(INTINF)), int_rng(oc_rng(def), oc_rng(pop)))))
    defm = def(2, lookup(def(1,:), m));
    popm = pop(2, lookup(pop(1,:), m));
    if(isin(m, oc_rng(trade_splice)))
      tradem = trade_splice(2, lookup(trade_splice(1,:), m));
      trade_totm = trade_tot(2, lookup(trade_tot(1,:), m));
      infnetm = 100*(deficit_m+tradem)/(debtm+trade_totm) - popm;
      INFNET = [INFNET, [m; infnetm]];
    endif
  endif
  % Phillips Curve
  if(isin(m, int_rng(int_rng(oc_rng(cpi), oc_rng(INFNET)), oc_rng(unrate))))
    unratem = unrate(2, lookup(unrate(1,:), m));
    emratem = emrate(2, lookup(emrate(1,:), m));
    cpim = cpi(2, lookup(cpi(1,:), m));
    infnetm = INFNET(2, lookup(INFNET(1,:), m));
    PH1 = [PH1, [m; emratem; cpim]];
    PH2 = [PH2, [m; emratem; cpim - infnetm]];
  endif
  % Real Interest Rates
  if(isin(m, int_rng(oc_rng(cpi), oc_rng(int_rt))))
    cpim = cpi(2, lookup(cpi(1,:), m));
    intm = int_rt(2, lookup(int_rt(1,:), m));
    R1 = [R1, [m; intm - cpim]];
  endif
  if(isin(m, int_rng(oc_rng(INFNET), oc_rng(R1))))
    R2 = [R2, [m; intm - (cpim - infnetm)]];
  endif
endwhile


% ================== Net Inflation ================ %
%{
plot(cpi(1,:)/12, cpi(2,:), "linewidth", 2, ";Consumer Price Index;");
hold on;
plot(INFNET(1,:)/12, INFNET(2,:), "linewidth", 2, ";Predicted Inflation;");
plot(unrate(1,:)/12, unrate(2,:), "linewidth", 2, ";Unemployment Rate;");
plot(recess(1,:)/12, 44*(recess(2,:)-.5), ":k");
hold off;
titl = title("Expected Monetary Inflation");
lege = legend("location", "southwest");
ylab = ylabel("Annual Percentage Rate");
axis([1965, 2023, -22, 20]);
set(lege, "fontsize", 14);
set(titl, "fontsize", 14);
set(ylab, "fontsize", 14);
%}
%=================== PHILLIPS Curve Dates===============%
ind = [70, 328, 411, 517, 553, 655, size(PH2)(2)];
months = [PH2(1, ind(1)), PH2(1,ind(2)), PH2(1,ind(3)), PH2(1,ind(4)), PH2(1,ind(5)), PH2(1,ind(6)), PH2(1,ind(7))];
yr1 = floor((months(1)-1) / 12)
mn1 = mod(months(1)-1, 12) + 1
yr2 = floor((months(2)-1) / 12)
mn2 = mod(months(2)-1, 12) + 1
yr3 = floor((months(3)-1) / 12)
mn3 = mod(months(3)-1, 12) + 1
yr4 = floor((months(4)-1) / 12)
mn4 = mod(months(4)-1, 12) + 1
yr5 = floor((months(5)-1) / 12)
mn5 = mod(months(5)-1, 12) + 1
yr6 = floor((months(6)-1) / 12)
mn6 = mod(months(6)-1, 12) + 1
yr7 = floor((months(7)-1) / 12 )
mn7 = mod(months(7)-1, 12) + 1
%================ PHILLIPS Unadjusted ==================%
%{
colormap(copper);
scatter(PH1(2,ind(1):ind(7)), PH1(3,ind(1):ind(7)), 36, PH1(1,ind(1):ind(7)), "o", "filled");
titl = title("Consumer Price Index Phillips Curve");
lege = legend("Aug 1971 (black) -\nSep 2021 (copper)", "location", "northwest");
ylab = ylabel("Annual Inflation (%)");
axis([84, 98, -4, 16]);
xlab = xlabel("Employment (%)");
set(lege, "fontsize", 12);
set(titl, "fontsize", 14);
set(xlab, "fontsize", 14);
set(ylab, "fontsize", 14);
%}
%================= Adjusted Single Span =================%
%{
colormap(copper);
scatter(PH2(2,ind(1):ind(7)), PH2(3,ind(1):ind(7)), 36, PH2(1,ind(1):ind(7)), "o", "filled");
lege = legend("Aug 1971 (black) -\nSep 2020 (copper)", "location", "northwest");
titl = title("Expectations-Augmented Phillips Curve");
ylab = ylabel("Inflation Expectations Gap (%)");
xlab = xlabel("Employment (%)");
set(lege, "fontsize", 12);
set(titl, "fontsize", 14);
set(xlab, "fontsize", 14);
set(ylab, "fontsize", 14);
axis([84, 98, -23, 27]);
%}
%================ Broken Up By Year Ranges================%
%{
scatter(PH2(2,ind(1):ind(2)-1), PH2(3,ind(1):ind(2)-1), 36, "k", "o", "filled");
hold on;
scatter(PH2(2,ind(2):ind(3)-1), PH2(3,ind(2):ind(3)-1), 36, "b", "o", "filled");
scatter(PH2(2,ind(3):ind(4)-1), PH2(3,ind(3):ind(4)-1), 36, "r", "o", "filled");
scatter(PH2(2,ind(4):ind(5)-1), PH2(3,ind(4):ind(5)-1), 36, [.6,.2,.9], "o", "filled");
scatter(PH2(2,ind(5):ind(6)-1), PH2(3,ind(5):ind(6)-1), 36, [.1,.5,.25], "o", "filled");
scatter(PH2(2,ind(6):ind(7)-1), PH2(3,ind(6):ind(7)-1), 36, [.91,.57,.36], "o", "filled");
hold off;
lege = legend("Aug 1971 - Jan 1993", "Feb 1993 - Dec 1999", "Jan 2000 - Oct 2008", "Nov 2008 - Nov 2011", "Dec 2011 - May 2020", "Jun 2020 - Sep 2021", "location", "northwest");
titl = title("Expectations-Augmented Phillips Curve");
ylab = ylabel("Inflation Expectations Gap (%)");
axis([84, 98, -27, 23]);
xlab = xlabel("Employment (%)");
set(lege, "fontsize", 12);
set(titl, "fontsize", 14);
set(xlab, "fontsize", 14);
set(ylab, "fontsize", 14);
%
%}
%============================= Interest and Inflation ==============%
%{
plot(home_apr(1,:)/12, home_apr(2,:), "linewidth", 2, ";30yr Fixed Rate Mortgage (Ave);");
hold on;
plot(int_rt(1,:)/12, int_rt(2,:), "linewidth", 2, ";Federal Funds Rate;");
plot(cpi(1,:)/12, cpi(2,:), "linewidth", 2, ";Consumer Price Index;");
plot(recess(1,:)/12, 40*(recess(2,:)-.5), ":k;US Recession;");
hold off;
lege = legend("location", "northeast");
titl = title("Medium Frequency Recessions, Long Term Decline");
axis([1962, 2023, -2, 20]);
ylab = ylabel("Annual Percentage Rate");
set(lege, "fontsize", 14);
set(titl, "fontsize", 14);
set(ylab, "fontsize", 14);
%}

%{
plot(wage_change(1,:)/12, wage_change(2,:), R2(1,:)/12, R2(2,:)/6, recess(1,:)/12, 10*(recess(2,:)-.5), drgdp(1,:)/12, drgdp(2,:));
%}

plot(totra(1,:)/12, totra(2,:), ";Total Resources and Assets (TOTRA);");
hold on;
plot(walcl(1,:)/12, walcl(2,:), ";Total Assets (WALCL);");
plot(curaccount_trade(1,:)/12, curaccount_trade(2,:), ";Trade Balance on Current Account (BOPBCA);");
plot(trade(1,:)/12, trade(2,:), ";Trade Balance on Payments (BOPGSTB);");
plot(deficit(1,:)/12, -deficit(2,:), ";Federal Deficit (FYFSD);");
lege = legend("location", "northwest");
hold off;
