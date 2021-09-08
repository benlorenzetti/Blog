clear;
clc;
addpath("C:/Users/Ben\ Lorenzetti/Documents/Blog/Economic-Data");
run('econdata.m');
run('real_estate_eqs.m');

apr = s2m_data(import_fred_csv('MORTGAGE30US.csv'));   % percent apr
Vmed = s2m_data(import_fred_csv('MSPUS.csv'));             % dollars
Iindex = s2m_data(import_fred_csv('CUUR0000SEHA.csv')); % unitless
recess = s2m_data(import_fred_csv('JHDUSRGDPBR.csv'));  % 0 or 1

shiller = import_shiller_csv('ie_data.csv');
price = shiller_series(shiller, 2);
earnings10yr = moving_ave(shiller_series(shiller, 4), 120);
pe10 = divide_series(price, earnings10yr);
ep10(1,:) = pe10(1,:);
ep10(2,:) = 1./pe10(2,:);

RN = [];
Rreal = [12*1960+1:12*2022 ; 180*ones(1,12*62)];
Rth = [];
YRTH = [];
norm_yr = 1999;
norm_mn = 1;
i = differentiate_series(moving_ave(Iindex, 60));
i(2,:) = 100*((1+i(2,:)).^(12) - 1);
scale = Vmed(2,lookup(Vmed(1,:),(norm_yr-1)*12+norm_mn));
scale = scale / Iindex(2,lookup(Iindex(1,:), (norm_yr-1)*12+norm_mn));
R1 = Rmort(apr(2,lookup(apr(1,:),(norm_yr-1)*12+norm_mn)), 360);
R2 = Rreal(2, lookup(Rreal(1,:), (norm_yr-1)*12+norm_mn));
scale = scale / (R1*R2/(R1+R2));
Iindex(2,:) = scale * Iindex(2,:);
Rpr = [];
c = [];
L = [12*1960+1:12*2022 ; 4*ones(1,12*62)];
f = [12*1960+1:12*2022 ; 0.07*ones(1,12*62)];
EY = [];
XY = [];
Y = [];
YPE = [];

start_yr = 1980;
end_yr = 2022;

m = (start_yr-1) * 12;
while(m < end_yr * 12)
  m = m + 1;
  %-------------- R(N) ------------------
  if(isin(m, oc_rng(apr)))
    aprm = apr(2,lookup(apr(1,:),m));
    Rm = Rmort(aprm, 360);
    RN = [RN, [m; Rm]];
    %------------- Rth ------------------
    if(isin(m, oc_rng(Rreal)))
      Rreali = Rreal(2, lookup(Rreal(1,:), m));
      Rpar = Rm * Rreali / (Rm + Rreali);
      Rth = [Rth, [m; Rpar]];
      YRTH = [YRTH, [m; 12/Rpar]];
    endif % Rth
  endif % R(N)
  %------------------ Rpr ------------------
  if(isin(m, int_rng(oc_rng(Vmed), oc_rng(Iindex))))
    V = Vmed(2, lookup(Vmed(1,:), m));
    Itemp = Iindex(2, lookup(Iindex(1,:), m));
    Rprtemp = V/Itemp;
    Rpr = [Rpr, [m; Rprtemp]];
    %------------------ c -------------------
    if(isin(m, oc_rng(Rth)))
      cm = Rprtemp/Rpar;
      c = [c, [m; cm]]; 
    endif % Rpr
  endif % c
  %------------------------ Equity Yield % APR --------------------
  if(isin(m, int_rng(int_rng(oc_rng(f), oc_rng(L)), int_rng(oc_rng(apr), oc_rng(i)))))
    fm = f(2, lookup(f(1,:), m));
    Lm = L(2, lookup(L(1,:), m));
    im = i(2, lookup(i(1,:), m));
    opt_ptm = opt_brute(fm, Lm, aprm, im, 360)(1);
    eym = other_pt(opt_ptm, fm, Lm, aprm, im, 360)(4);
    EY = [EY, [m; eym]];
    %------------------- External Yield / Combined Yield -----------------
    if(isin(m, oc_rng(c)))
      xym = 100*((1+x_yield(opt_ptm, fm, Lm, aprm, im, 360, cm))^12 - 1);
      XY = [XY, [m; xym]];
      ym = eym + xym;
      Y = [Y, [m; ym]];
      YPE = [YPE, [m; 100/ym]];
    endif
  endif
endwhile

plot(pe10(1,:)/12, pe10(2,:), ";S&P 500 P/E Ratio;");
hold on;
plot(YPE(1,:)/12, 3*YPE(2,:), ";3x Mortgage P/E;");
plot(RN(1,:)/12, RN(2,:)/12, ";R(N) All Cash P/E;");
plot(recess(1,:)/12, 50*recess(2,:), ":k;US Recessions;");
hold off;
lg = legend("location", "northwest");
ylab = ylabel("Price to Annual Earnings Ratio");
axis([1975, 2022, 0, 50]);
ti = title("Historical Comparison of Stock Prices, Home Prices, and Interest Rates");
text(1972, -3.75, "Sources: MORTGAGE30US, MSPUS, CUUR0000SEHA (FRED) and U.S. Stock Markets 1871-Present (Shiller)");
text(1977, -5.75, "with L = 4, f = .07, Rexp = 180 months, and rent index normalized to model in Jan. 1999");
set(lg, "fontsize", 12);
set(ti, "fontsize", 14);
set(ylab, "fontsize", 14);
