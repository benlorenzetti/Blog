clear;
clc;
% addpath("path");
run('real_estate_eqs.m');

function Yarray = mortgage_yield_array(APR, IPR, N, L, c, OPR, T)
  m = 0;
  do
    m = m + 1;
    G = mortgage_performance(m, APR, IPR, N, L, c, OPR, T);
    y = nthroot(G+1, m);
    Yarray(m) = 100*(y^12 - 1);
  until(m == N)  
endfunction

function exp = power_array(apr, N)
  frac = (apr/100)^(1/12);
  m = 0;
  do
    m = m + 1;
    exp(m) = frac^m;
  until(m == N)
endfunction

L = 4;
APR1 = 4.75;
APR2 = 5.25;
IPR = 5;
OPR = 8;
T1 = 8;
T2 = 12;
N1 = 180;
N2 = 360;
c1 = 0.35;
c2 = 0.48;
n1 = 1:N1;
n2 = 1:N2;

Y1 = mortgage_yield_array(APR1, IPR, N1, L, c1, OPR, T1);
Y2 = mortgage_yield_array(APR2, IPR, N2, L, c2, OPR, T2);

quad_n1 = simple_mortgage_period(APR1, IPR, N1, L, c1, OPR, T1);
quad_G1 = mortgage_performance(quad_n1, APR1, IPR, N1, L, c1, OPR, T1);
quad_y1 = nthroot(quad_G1 + 1, quad_n1);
quad_apr1 = 100*(quad_y1^12 - 1);

quad_n2 = simple_mortgage_period(APR2, IPR, N2, L, c2, OPR, T2);
quad_G2 = mortgage_performance(quad_n2, APR2, IPR, N2, L, c2, OPR, T2);
quad_y2 = nthroot(quad_G2 + 1, quad_n2);
quad_apr2 = 100*(quad_y2^12 - 1);
%{
start = ceil(pt1(1)+1);
op2 = start + lookup(plus2f(start:N) .-eq_exp(start:N), 0);
pt2 = other_pt(op2, f, L, APR, IPR, N);
%}

% PART I: Equity Buildup Graph
%{
plot(n,mul2,";4% Inflation;", n, pos1,";2% Inflation;");
hold on
plot(n,zero,";0% Inflation;", n, neg1,";-2% Inflation;");
plot(n,Rmort(APR,N)*ones(1,N),":k", n, N*ones(1,N),":k");
t = title("Equity Buildup of 30-Year, 2% APR Mortgage");
l = legend("location","west");
y = ylabel("Equity Buildup / (Monthly Mortgage Payment)");
x = xlabel("months");
axis([0,360,0,400]);
hold off
set(l, "fontsize", 12);
set(t, "fontsize", 14);
set(y, "fontsize", 14);
set(x, "fontsize", 12);
%}

% PART II: Quadratic Formula Graphs
%{
plot(n/12, plus2f, ";2% Inflation (IPR = APR);", n/12, zerof, ";0% Inflation;");
hold on
plot(n/12, minus2f, ";-2% Inflation;", n/12, eq_exp, ":k;eq. yield approx. (7.2%);");
plot(pt1(1)/12, pt1(2), "xk", pt2(1)/12, pt2(2), "xk");
t = title("L = 4, f = 0.07 Refinance Window for 30-Year, 2% APR Mortgage");
l = legend("location","northwest");
y = ylabel("Equity Gain / Cash to Close");
axis([0,30,0,6]);
hold off
set(l, "fontsize", 12);
set(t, "fontsize", 14);
set(y, "fontsize", 14);
%}

% PART III: Peak Shifting
%
p1 = plot(n1/12, Y1, ";15 Yr (c = 0.35, L = 4, I = 4.75% Pi = 5%, Rho = 8% and T = 8 months);");
hold on;
p2 = plot(n2/12, Y2, ";30 Yr (c = 0.48, L = 4, I = 5.25% Pi = 5%, Rho = 8% and T = 12 months);");
p3 = plot(quad_n1/12, quad_apr1, "xk;Quadratic Optimum Period;");
plot(quad_n2/12, quad_apr2, "xk");
hold off;
l = legend([p1,p2,p3],"location","south");
t = title("Constant Inflation Mortgage Yield");
y = ylabel("Annual Percentage Rate");
axis([0,30,0,12]);
set(l, "fontsize", 10);
set(t, "fontsize", 14);
set(y, "fontsize", 14);
