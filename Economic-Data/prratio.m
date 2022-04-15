clear;
clc;
run('econdata.m'); % Functions for importing and manipulating data

mort30us = s2m_data(import_fred_csv('Data\MORTGAGE30US.csv'));   % percent apr
mspus = s2m_data(import_fred_csv('Data\MSPUS.csv'));             % dollars
rent_index = s2m_data(import_fred_csv('Data\CUUR0000SEHA.csv')); % unitless
recessions = import_fred_csv('Data\JHDUSRGDPBR.csv');  % 0 or 1

apr_range = months_range(mort30us, mort30us);
apr = stretch_align_index(mort30us, apr_range);
mpr = (1 + apr(2,:)./100).^(1/12);
Rmort = (1-mpr.^(-360)) ./ (1 - 1./mpr);
Rreal = 180;
Rth(1,:) = apr(1,:);
Rth(2,:) = (Rreal * Rmort)./(Rmort + Rreal);

norm_year = 2015;
norm_month = 12;
pr_range = months_range(mspus, rent_index);
Vmed = stretch_align_index(mspus, pr_range);
Irent = stretch_align_index(rent_index, pr_range);
ind1 = lookup(Rth(1,:), 12*norm_year + norm_month);
ind2 = lookup(Vmed(1,:), 12*norm_year + norm_month);
scale = Rth(2,ind1) / (Vmed(2,ind2)/(Irent(2,ind2)));
pr_index(1,:) = pr_range(1) : pr_range(2);
pr_index(2,:) = scale * Vmed(2,:)./Irent(2,:);

m2v = s2m_data(import_fred_csv('Data\M2V.csv'));
m2p(1,:) = m2v(1,:);
m2p(2,:) = 1./m2v(2,:);
ind3 = lookup(m2p(1,:), 12*norm_year + norm_month);
scale3 = Rth(2,ind1) / m2p(2,ind3);
m2p_index(1,:) = m2p(1,:);
m2p_index(2,:) = m2p(2,:) * scale3; 

%{
plot(pr_index(1,:)/12, pr_index(2,:), "linewidth", 2, ';US Median Sales P/R Index;');
hold on;
plot(Rth(1,:)/12, Rth(2,:), "linewidth", 2, ';Mortgage Dividend R(pr);');
plot(m2p_index(1,:)/12, m2p_index(2,:), ";M2T;");
plot(recessions(1,:)/12, 80*recessions(2,:)+40, "k:;US Recessions;");
hold off;
titl = title("Median Sales Price to Rent Index, normalized at Dec. 2015, 97.3");
lege = legend("location","northwest");
ylab = ylabel("Months of Rent");
axis([1968, 2023,40,120]);
set(lege, "fontsize", 14);
set(titl, "fontsize", 14);
set(ylab, "fontsize", 14);
%}


d1 = differ(Rth);
d1div = Rth;
d1div(:,1) = [];
d1(2,:) = 12*d1(2,:) ./ d1div(2,:);
d2 = differ(pr_index);
d2div = pr_index;
d2div(:,1) = [];
d2(2,:) = 12* d2(2,:) ./ d2div(2,:);
d3 = differ(m2p_index);
d3div = m2p_index;
d3div(:,1) = [];
d3(2,:) = 12* d3(2,:) ./ d3div(2,:);
maveT = 60;
d1 = moving_ave(d1, maveT);
d2 = moving_ave(d2, maveT);
d3 = moving_ave(d3, maveT);
plot(d2(1,:)/12, 100*d2(2,:), d1(1,:)/12, 100*d1(2,:), d3(1,:)/12, 100*d3(2,:));
axis([1968, 2023, -.25, .25]);