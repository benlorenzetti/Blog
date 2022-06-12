clear;
clc;
% addpath("path");
run('real_estate_eqs.m');

function array = buildup_time_array(apr, ipr, N)
  m = 0;
  do
    m = m + 1;
    array(m) = equity_buildup_time(m, apr, ipr, N);
  until(m == N)
endfunction

function array = buildup_frac_array(f, L, apr, ipr, N)
  m = 0;
  do
    m = m + 1;
    array(m) = equity_buildup_frac(m, f, L, apr, ipr, N);
  until(m == N)
endfunction

function exp = power_array(frac, N)
  m = 0;
  do
    m = m + 1;
    exp(m) = frac^m;
  until(m == N)
endfunction

function array = buildup_x_array(f, L, APR, IPR, N, c)
  m = 0;
  do
    m = m + 1;
    array(m) = x_yield(m,f,L,APR,IPR,N,c);
  until(m == N)
endfunction

function array = buildup_e_array(f, L, APR, IPR, N)
  m = 0;
  do
    m = m + 1;
    array(m) = e_yield(m,f,L,APR,IPR,N);
  until(m == N)
endfunction

f = 0.07; % 0.07
L = 4;   % 11
APR = 1.875;  % 1.875
IPR = 4; % 2.5
N = 180;   % 360
c = 1;     % 1
n = 1:N;

mul2 = buildup_time_array(APR, 2*APR, N);
pos1 = buildup_time_array(APR, APR, N);
zero = buildup_time_array(APR, 0, N);
neg1 = buildup_time_array(APR, -APR, N);

plus2f = buildup_frac_array(f, L, APR, IPR, N);
zerof = buildup_frac_array(f, L, APR, 0, N);
minus2f = buildup_frac_array(f, L, APR, -IPR, N);

pt1 = opt_pt(f, L, APR, IPR, N);
eq_exp = power_array(pt1(3), N);
start = ceil(pt1(1)+1);
op2 = start + lookup(plus2f(start:N) .-eq_exp(start:N), 0);
pt2 = other_pt(op2, f, L, APR, IPR, N);

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
external = 100*((1+buildup_x_array(f,L,APR,IPR,N,c)).^12 - 1);
internal = 100*((1+buildup_e_array(f,L,APR,IPR,N)).^12 - 1);
plot(n/12, external.+internal, ";(Y) Net Yield (2% Inflation);");
hold on;
plot(n/12, internal, ";(y-1) Equiv. Equity Yield (2% Infl.);");
plot(n/12, external, ";(X) External Dividend (2% Inflation);");
plot(pt1(1)/12, pt1(4), "xk;INF = INT Quadratic Point;");
hold off;
l = legend("location","northeast");
t = title("Cash Flow Peak Shift for L = 4, f = .07, c = 1, 30-year, 2% APR Mortgage");
y = ylabel("Annual Percentage Rate");
axis([0,30,0,20]);
set(l, "fontsize", 12);
set(t, "fontsize", 14);
set(y, "fontsize", 14);
