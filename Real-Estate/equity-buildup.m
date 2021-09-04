clear;
clc;
% addpath("path");
run('real-estate-eqs.m');

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
function exp = exp_array(frac, N) 
  m = 0;
  do
    m = m + 1;
    exp(m) = frac^m;
  until(m == N)
endfunction

f = 0.07;
L = 4;
APR = 2;
IPR = 2;
N = 360;
n = 1:N;

mul2 = buildup_time_array(APR, 2*APR, N);
pos1 = buildup_time_array(APR, APR, N);
zero = buildup_time_array(APR, 0, N);
neg1 = buildup_time_array(APR, -APR, N);

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

%{
plus2 = buildup_frac_array(f, L, APR, IPR, N);
zero = buildup_frac_array(f, L, APR, 0, N);
minus2 = buildup_frac_array(f, L, APR, -IPR, N);

pt1 = opt_pt(f, L, APR, IPR, N);
eq_exp = exp_array(pt1(3), N);
start = ceil(pt1(1)+1);
op2 = start + lookup(plus2(start:N) .-eq_exp(start:N), 0);
pt2 = other_pt(op2, f, L, APR, IPR, N);

plot(n/12, plus2, ";2% Inflation (IPR = APR);", n/12, zero, ";0% Inflation;");
hold on 
plot(n/12, minus2, ";-2% Inflation;", n/12, eq_exp, ":k;eq. yield approx. (7.2%);");
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