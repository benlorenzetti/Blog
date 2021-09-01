clear;
clc;

run('econdata.m');

cpi = import_fred_csv('Data\CPIAUCSL.csv');
gdp = import_fred_csv('Data\FYGDP.csv');
debt = import_fred_csv('Data\GFDEBTN.csv');
intr = import_fred_csv('Data\INTDSRUSM193N.csv');
recessions = import_fred_csv('Data\JHDUSRGDPBR.csv');

rates_range = months_range(intr, cpi);
inf1 = stretch_align_index(cpi, rates_range);
intr = stretch_align_index(intr, rates_range);

filter = 60;
debt = stretch_align_index(debt, months_range(debt, debt));
dddn = differentiate_series(moving_ave(debt, filter));
dddn(1,:) = dddn(1,:) + 0;
dddn(2,:) = 1200 * dddn(2,:) ./ debt(2,filter/2 + 2:size(debt)(2)-filter/2);
zero(1,:) = 1960*12 : 2025*12;
zero(2,:) = 0;
intr(1,:) = intr(1,:) -0;
diff_range = months_range(intr, dddn);
d1 = stretch_align_index(intr, diff_range);
d2 = stretch_align_index(dddn, diff_range);
inf_exp(1,:) = diff_range(1) : diff_range(2);
scale = .25;
intcpt = 0;
inf_exp(2,:) = scale*(d1(2,:) .+ d2(2,:)) + intcpt;

inf2 = import_fred_csv('Data\FPCPITOTLZGUSA.csv');
inf3 = import_fred_csv('Data\CPILFESL.csv');
inf4 = import_fred_csv('Data\CUUR0000SEHA.csv');
inf5 = import_fred_csv('Data\CPIEMEDCARE.csv');

ymin = -5;
ymax = 20;
plot(intr(1,:)/12, intr(2,:), dddn(1,:)/12, dddn(2,:), inf_exp(1,:)/12, inf_exp(2,:), inf3(1,:)/12, inf3(2,:), recessions(1,:)/12, (ymax-ymin)*(recessions(2,:)+(ymin/(ymax-ymin))), 'k:', zero(1,:)/12, zero(2,:));
legend("A. Federal Discount Rate", "B. d/dt (Fed. Debt)", "M. Scaled*Mean(A, B)", "C. CPI Less Food/Energy", "location", "southwest");
axis([1965, 2025, ymin, ymax]);
title("Inflation");