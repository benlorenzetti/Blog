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

    % 201 Delaware, 6/22 vs 405 W Alexander 10/21
L = 4;  % 4, 15
APR1 = 4.75; % 4.75, 2.25
APR2 = 5.25; % 5.25, 1.875
IPR = 5; % 5, 2.5
OPR = 8; % 8, 10
T1 = 8;  % 8, 10
T2 = 12;  % 12, 18
N1 = 180; 
N2 = 360;
c1 = 0.35; % 0.35, 0.41
c2 = 0.48; % 0.48, 0.67
n1 = 1:N1;
n2 = 1:N2;

Y1 = mortgage_yield_array(APR1, IPR, N1, L, c1, OPR, T1);
Y2 = mortgage_yield_array(APR2, IPR, N2, L, c2, OPR, T2);

tau1 = quadratic_mortgage_period(APR1, IPR, N1, L, c1, OPR, T1)
Gtau1 = mortgage_performance(tau1, APR1, IPR, N1, L, c1, OPR, T1)
ytau1 = nthroot(Gtau1 + 1, tau1);
APRtau1 = 100*(ytau1^12 - 1);

quad_n2 = quadratic_mortgage_period(APR2, IPR, N2, L, c2, OPR, T2);
quad_G2 = mortgage_performance(quad_n2, APR2, IPR, N2, L, c2, OPR, T2);
quad_y2 = nthroot(quad_G2 + 1, quad_n2);
quad_apr2 = 100*(quad_y2^12 - 1);


A1 = L / Rmort(APR1, N1);
omega1 = realpow(1+OPR/100, 1/12)
pi1 = realpow(1+IPR/100, 1/12)
rho1 = omega1 / pi1
i1 = realpow(1+APR1/100, 1/12)
R1 = i1 - pi1
Omega1 = omega1 - 1;
Rho1 = rho1 - 1;
I1 = i1 - 1;
tau_omega_1 = (omega1^tau1 - 1)/Omega1
tau_rho_1 = (rho1^tau1 - 1)/Rho1
tau_i_1 = (i1^tau1 - 1)/I1
a1 = c1*omega1^(tau1+1) - rho1^(tau1+1) + 1 - (i1*R1/I1) * (1 - i1^(tau1+1-N1))
b1 = T1 - c1*omega1*(tau_omega_1 - tau1*omega1^tau1);
b1 = b1 + rho1*(tau_rho_1 - tau1*rho1^tau1);
b1 = b1 - (R1*i1^(2-N1)/I1)*(tau_i_1 - tau1*i1^tau1)
d1 = c1*Omega1*omega1^(tau1+1) - Rho1*rho1^(tau1+1) + R1*i1^(tau1+2-N1)
B1 = (-3*(A1^3)*(a1^2)*b1 - (A1^2)*(a1^2) + 2*A1*d1) / ((A1*a1)^3)
C1 = (3*(A1^3)*a1*(b1^2) + 2*(A1^2)*a1*b1 - 2*A1*d1*tau1) / ((A1*a1)^3)
D1 = (-(A1*b1)^3 - (A1*b1)^2 + 2*A1*b1) / ((A1*a1)^3)
p1 = C1/3 - (B1/3)^2
q1 = (B1/3)^3 - (C1/2)*(B1/3) + D1/2
cubic1 = -B1/3 - (q1 + sqrt(p1^3 + q1^2))^(1/3) - (q1 - sqrt(p1^3 + q1^2))^(1/3)
cubic1 = round(abs(real(cubic1)))
Gcubic1 = mortgage_performance(cubic1, APR1, IPR, N1, L, c1, OPR, T1)
yn1 = nthroot(Gcubic1 + 1, cubic1)
APRcubic1 = 100*(yn1^12 - 1)

p1 = plot(n1, Y1, ";15 Yr (c = 0.35, L = 4, I = 4.75% Pi = 5%, Rho = 8% and T = 8 months);");
hold on;
p2 = plot(n2, Y2, ";30 Yr (c = 0.48, L = 4, I = 5.25% Pi = 5%, Rho = 8% and T = 12 months);");
p3 = plot(tau1, APRtau1, "xk;Quadratic Optimum Point;");
p4 = plot(cubic1, APRcubic1, "ok;Cubic Optimum Point;");
plot(quad_n2, quad_apr2, "xk");
hold off;
l = legend([p1,p2,p3, p4],"location","south");
t = title("Mortgage Yield with Constant Projected Inflation");
y = ylabel("Annual Percentage Rate");
axis([0,360,0,16]);
set(l, "fontsize", 10);
set(t, "fontsize", 14);
set(y, "fontsize", 14);
