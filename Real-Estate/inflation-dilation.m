clear;
clc;
function months = months_eq_equity_buildup(apr, ipr, coverp, N, n)
  inf = realpow(1+ipr/100, 1/12);
  r = realpow(1+apr/100, 1/12);
  c1 = (inf-r)/(1-1/r);
  c2 = (r^(-N))/(1-1/r);
  months = n + c1*(n-c2*(r^n - 1)) - coverp*inf^n;
endfunction

function buildup = buildup_array(apr, ipr, coverp, N) 
  m = 0;
  do
    m = m + 1;
    buildup(m) = months_eq_equity_buildup(apr, ipr, coverp, N, m);
  until(m == N)
endfunction

function opt_point = optimum_point(apr, ipr, coverp, N)
  derivative_zero = buildup_array(apr, ipr, coverp, N);
  r = (1 + apr/100)^(1/12);
  inf = (1 + ipr/100)^(1/12);
  derivative_zero = derivative_zero .- 2*(1+(r - inf)/(1 - 1/r));
  n = 1 + lookup(derivative_zero, 0);
  buildup = months_eq_equity_buildup(apr, ipr, coverp, N, n);
  c = (1 - r^(-N))/(1-1/r);
  annual_yield_multiplier = (1+buildup/c)^(12/n);
  annual_div = 100*(annual_yield_multiplier - 1);
  opt_point = [n, buildup, annual_div];
endfunction

function optimum = optimum_buildup(apr, ipr, N)
  r = (1 + apr/100)^(1/12);
  inf = (1 + ipr/100)^(1/12);
  optimum = 2*(1+(r - inf)/(1 - 1/r)) + zeros(1,N);
endfunction

n = 1:360;
plus2 = buildup_array(2, 2, 12, 360);
plus2op = optimum_buildup(2, 2, 360);
plus2pt = optimum_point(2, 2, 12, 360);

zero = buildup_array(2, 0, 12, 360);
zeroop = optimum_buildup(2, 0, 360);
zeropt = optimum_point(2, 0, 12, 360);

minus2 = buildup_array(2, -2, 12, 360);
minus2op = optimum_buildup(2, -2, 360);
minus2pt = optimum_point(2, -2, 12, 360);

plot(n, plus2, n, zero, n, minus2, n, plus2op, n, zeroop, n, minus2op, plus2pt(1), plus2pt(2), "xk", zeropt(1), zeropt(2), "xk", minus2pt(1), minus2pt(2), "xk");
title("Nominal Home Equity Gains for 2%, 30-year Mortgage");
legend("2% Inflation, 12-month Refin. Cost", "0% Inflation, 12-month Refin. Cost", "-2% Inflation, 12-month Refin. Cost", "location","northwest");
ylabel("Equity Gains / Monthly Payment (months)");
xlabel("months");
axis([0,360,-12,360]);

%{
for i = 1:800
  inf(i) = i/100 -4;
  div6(i) = optimum_point(2, inf(i), 6, 360)(3);
  div12(i) = optimum_point(2, inf(i), 12, 360)(3);
endfor
interest = zeros(1,800);
interest(600) = 1.75;
plot(inf, div6, inf, div12, inf, interest, 'k');
title("Liability Dividend Yield for 2%, 30-year Mortgage");
ylabel("Annual Equivalent Yield (%)");
xlabel("Home Price Inflation (%)");
legend("6-month mort. payment equivalent Refinancing Cost", "12-month mort. payment equivalent Refinancing Cost", "location","northwest");
axis([-4,4,0,1.75]);
%}
