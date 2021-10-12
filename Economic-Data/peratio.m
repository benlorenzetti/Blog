% Copyright 2021 Ben Lorenzetti
%
% Permission is hereby granted, free of charge, to any person obtaining a copy 
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
clear;
clc;
run('econdata.m');
run('real_estate_eqs.m');

apr = s2m_data(import_fred_csv('Data/MORTGAGE30US.csv'));   % percent apr
Vmed = s2m_data(import_fred_csv('Data/MSPUS.csv'));             % dollars
Iindex = s2m_data(import_fred_csv('Data/CUUR0000SEHA.csv')); % unitless
recess = import_fred_csv('Data/JHDUSRGDPBR.csv');  % 0 or 1
shiller = import_shiller_csv('Data/ie_data.csv');
price = shiller_series(shiller, 2);
earnings10yr = moving_ave(shiller_series(shiller, 4), 60);
pe10 = divide_series(price, earnings10yr);
dpct = s2m_data(import_fred_csv("C:/Users/benlo/Documents/pct-down.csv"));

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
L1 = [12*1960+1:12*2022 ; 4*ones(1,12*62)];
L2 = [12*1960+1:12*2022 ; 8*ones(1,12*62)];
f = [12*1960+1:12*2022 ; 0.07*ones(1,12*62)];
EY = [];
XY = [];
Y = [];
YPE = [];
EY2 = [];
XY2 = [];
Y2 = [];
YPE2 = [];

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
  %------------------------L1  Equity Yield % APR --------------------
  if(isin(m, int_rng(int_rng(oc_rng(f), oc_rng(L1)), int_rng(oc_rng(apr), oc_rng(i)))))
    fm = f(2, lookup(f(1,:), m));
    L1m = L1(2, lookup(L1(1,:), m));
    im = i(2, lookup(i(1,:), m));
    opt_ptm = brute_opt(fm, L1m, aprm, im, 360)(1);
    eym = other_pt(opt_ptm, fm, L1m, aprm, im, 360)(4);
    EY = [EY, [m; eym]];
    %------------------- L1 External Yield / Combined Yield -----------------
    if(isin(m, oc_rng(c)))
      xym = 100*((1+x_yield(opt_ptm, fm, L1m, aprm, im, 360, cm))^12 - 1);
      XY = [XY, [m; xym]];
      ym = eym + xym;
      Y = [Y, [m; ym]];
      YPE = [YPE, [m; 100/ym]];
    endif
  endif
  %------------------------L2  Equity Yield % APR --------------------
  if(isin(m, int_rng(int_rng(oc_rng(f), oc_rng(dpct)), int_rng(oc_rng(apr), oc_rng(i)))))
    fm = f(2, lookup(f(1,:), m));
    dpctm = dpct(2, lookup(dpct(1,:), m));
    L2m = 100/dpctm;
    L2 = [L2, [m; L2m]];
    im = i(2, lookup(i(1,:), m));
    opt_pt2m = brute_opt(fm, L2m, aprm, im, 360)(1);
    ey2m = other_pt(opt_pt2m, fm, L2m, aprm, im, 360)(4);
    EY2 = [EY2, [m; ey2m]];
    %------------------- L2 External Yield / Combined Yield -----------------
    if(isin(m, oc_rng(c)))
      xy2m = 100*((1+x_yield(opt_pt2m, fm, L2m, aprm, im, 360, cm))^12 - 1);
      XY2 = [XY2, [m; xy2m]];
      y2m = ey2m + xy2m;
      Y2 = [Y2, [m; y2m]];
      YPE2 = [YPE2, [m; 100/y2m]];
    endif
  endif
endwhile

plot(pe10(1,:)/12, pe10(2,:), ";S&P 500 5YR P/E;");
hold on;
plot(YPE(1,:)/12, 2.75*YPE(2,:), ";2.75x Mortgage P/E;");
plot(RN(1,:)/12, RN(2,:)/12, ";R(N) All Cash P/E;");
plot(recess(1,:)/12, 50*recess(2,:), ":k;US Recessions;");
plot(YPE2(1,:)/12, 2.75*YPE2(2,:), ":k;Freddie Mac Overlay;");
hold off;
lg = legend("location", "northwest");
ylab = ylabel("Price to Earnings Ratio (Annual)");
axis([1976, 2022, 0, 40]);
ti = title("Comparison of Stock Prices, Home Prices, and Interest Rates");
text(1972, -3.25, "Sources: MORTGAGE30US, MSPUS, CUUR0000SEHA (FRED) and U.S. Stock Markets 1871-Present (Shiller)");
text(1976, -4.75, "with L = 4, f = .07, Rexp = 180 months, c' = 1, and rent index normalized to model in Jan. 1999");
set(lg, "fontsize", 12);
set(ti, "fontsize", 14);
set(ylab, "fontsize", 14);
