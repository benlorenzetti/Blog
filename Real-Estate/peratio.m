clear;
clc;
function incl_range = months_range(series1, series2)
  first = max(series1(1,1), series2(1,1));
  last = min(series1(1,size(series1)(2)), series2(1,size(series2)(2)));
  incl_range = [first, last];
endfunction

% ldi(data): For data in 2xN, returns greatest i in N such that
% element (1,i) is non-zero.
function last_data_index = ldi(row)
  i = size(row)(2);
  while(i != 0 && row(1,i) == 0)
    i = i - 1;
  endwhile
  last_data_index = i;
endfunction

function shiller_data = import_shiller_csv(filename)
  shiller_data = csvread(filename);
  shiller_data(1:8,:) = []; % Remove First 8 Title Rows
  % Convert Date to Month Index
  shiller_data(:,1) = ceil(12*shiller_data(:,6));
  shiller_data(:,6) = []; % remove second data column
  shiller_data(:,7:24) = []; % remove non-source data columns
  shiller_data = shiller_data'; % Transpose to match plot expectations
  % Row Organization:
  % (1) Month, (2) S&P Price, (3) Dividend, (4) Earnings, (5) CPI, (6) GS10
  % Remove trailing data below last data
  shiller_data = shiller_data(:,1:ldi(shiller_data(1,:)));
endfunction

function series = shiller_series(shiller_data, series_row)
  series(1,:) = shiller_data(1, 1:ldi(shiller_data(series_row,:)));
  series(2,:) = shiller_data(series_row, 1:ldi(shiller_data(series_row,:)));
endfunction

function fred_data = import_fred_csv(filename)
  fred_data = csvread(filename);
  fred_data(1,:) = []; % remove title row
  % Convert year/month complex numbers to month index
  fred_data(:,1) = real(12*fred_data(:,1)) - imag(fred_data(:,1));
  fred_data = fred_data'; % transpose to row format for plotting
endfunction

function new_data = stretch_align_index(data, incl_range)
  m = 0;
  while(m <= incl_range(2) - incl_range(1))
    new_data(1,m+1) = m + incl_range(1);
    i = lookup(data(1,:), m + incl_range(1));
    new_data(2,m+1) = data(2,i);
    m = m + 1;
  endwhile
endfunction

function Rm = Rmort(apr, N)
  r = (1+apr(2,:)./100) .^ (1/12);
  Rm(1,:) = apr(1,:);
  Rm(2,:) = (1-r.^(-N)) ./ (1 - 1./r);
endfunction

function Rth = Rtarget_pr(Rm, Rreal)
  Rth(1,:) = Rm(1,:);
  Rth(2,:) = (Rreal .* Rm(2,:))./(Rm(2,:) .+ Rreal);
endfunction

function Rpar = parallel_series(R1, R2)
  incl_range = months_range(R1, R2);
  R1sub = stretch_align_index(R1, incl_range);
  R2sub = stretch_align_index(R2, incl_range);
  Rpar(1,:) = incl_range(1) : incl_range(2);
  Rpar(2,:) = R1sub(2,:) .* R2sub(2,:) ./ (R1sub(2,:) .+ R2sub(2,:));
endfunction

function prod = multiply_series(s1, s2)
  incl_range = months_range(s1, s2);
  s1 = stretch_align_index(s1, incl_range);
  s2 = stretch_align_index(s2, incl_range);
  prod(1,:) = incl_range(1) : incl_range(2);
  prod(2,:) = s1(2,:).*s2(2,:);
endfunction

function div = divide_series(s1, s2)
  incl_range = months_range(s1, s2);
  s1 = stretch_align_index(s1, incl_range);
  s2 = stretch_align_index(s2, incl_range);
  div(1,:) = incl_range(1) : incl_range(2);
  div(2,:) = s1(2,:)./s2(2,:);
endfunction

function pr_index = prindex(Vmedian, Irent)
  incl_range = months_range(Vmedian, Irent);
  V = stretch_align_index(Vmedian, incl_range);
  I = stretch_align_index(Irent, incl_range);
  pr_index(1,:) = V(1,:);
  pr_index(2,:) = V(2,:)./I(2,:);
endfunction

function new_index = normalize(index_data, real_data, year)
  irefpt = lookup(index_data(2,:), 12*year);
  rrefpt = lookup(real_data(2,:), 12*year);
  scale = real_data(2, rrefpt) / index_data(2, irefpt);
  new_index(1,:) = index_data(1,:);
  new_index(2,:) = index_data(2,:) * scale;
endfunction

function mave = moving_ave(data, last_n)
  lend = data(1,last_n);
  last = data(1,size(data)(2));
  i = 0;
  do
    i = i + 1;
    mave(1,i) = lend + i;
    mave(2,i) = sum(data(2,i:i+last_n))/last_n;
  until(i == last - lend)
endfunction

function apr = percentage_change(data, k)
  apr(1,:) = data(1,2:size(data)(2));
  mdiff = diff(data(2,:));
  mmult = 1 + mdiff ./ data(2,2:size(data)(2));  
  apr(2,:) = 100*(mmult.^12 - 1);
endfunction

function months = months_eq_equity_buildup(apr, ipr, coverp, N, n)
  inf = realpow(1+ipr/100, 1/12);
  r = realpow(1+apr/100, 1/12);
  c1 = (r-inf)/(1-1/r);
  c2 = (r^(-N))/(1-1/r);
  months = n - c1*(n-c2*(r^n - 1)) - coverp*inf^n;
endfunction

function buildup = buildup_array(apr, ipr, coverp, N) 
  m = 0;
  do
    m = m + 1;
    buildup(m) = months_eq_equity_buildup(apr, ipr, coverp, N, m);
  until(m == N)
endfunction
%{
% apr = mortgage annual percentage rate (APR)
% ipr = inflation APR
% coverp = Cost of refinancing / monthly mortgage payment
% N = loan period, in months
% L0 = initial effective leverage
%    = mortgage pricipal/(down payment + closing costs)
%
% n = optimum time for refinancing
% buildup = optimal capital gains from refinancing / monthly mortgage payment
% annual_div = capital gains APR, based on initial leverage
%}
function opt_point = optimum_point(apr, ipr, coverp, N, L0)
  derivative_zero = buildup_array(apr, ipr, coverp, N);
  r = (1 + apr/100)^(1/12);
  inf = (1 + ipr/100)^(1/12);
  derivative_zero = derivative_zero .- 2*(1+(r - inf)/(1 - 1/r));
  n = 1 + lookup(derivative_zero, 0);
  buildup = months_eq_equity_buildup(apr, ipr, coverp, N, n);
  annual_yield_multiplier = (1 + L0 * buildup/N)^(12/n);
  annual_div = 100*(annual_yield_multiplier - 1);
  opt_point = [n, buildup, annual_div];
endfunction


function Gl = Gliability_apr(apr, ipr, coverp, N, L0)
  incl_range = months_range(apr, ipr);
  aligned_apr = stretch_align_index(apr, incl_range);
  aligned_ipr = stretch_align_index(ipr, incl_range);
  Gl(1,:) = aligned_apr(1,:);
  i = 0;
  do
    i = i + 1;
    Gl(2,i) = optimum_point(aligned_apr(2,i), aligned_ipr(2,i), coverp, N, L0)(3);
  until(i == incl_range(2) - incl_range(1) + 1)
endfunction


mort30us = import_fred_csv('C:\Economic-Data\MORTGAGE30US.csv');   % percent apr
mspus = import_fred_csv('C:\Economic-Data\MSPUS.csv');             % dollars
rent_index = import_fred_csv('C:\Economic-Data\CUUR0000SEHA.csv'); % unitless
recessions = import_fred_csv('C:\Economic-Data\JHDUSRGDPBR.csv');  % 0 or 1

shiller = import_shiller_csv('C:\Economic-Data\shiller.csv');
price = shiller_series(shiller, 2);
earnings10yr = moving_ave(shiller_series(shiller, 4), 120);
pe10 = divide_series(price, earnings10yr);

Rm = Rmort(mort30us, 360);
Rpr_tgt = Rtarget_pr(Rm, 180);
Rpr_mkt = normalize(prindex(mspus, rent_index), Rpr_tgt, 2016);
rent_apr = percentage_change(moving_ave(rent_index, 60), 12);
Gl_apr = Gliability_apr(mort30us, rent_apr, 8, 360, 4);
Rl(1,:) = Gl_apr(1,:);
Rl(2,:) = (12*100)./Gl_apr(2,:);
Rm2(1,:) = Rm(1,:);
Rm2(2,:) = 4*Rm (2,:);
Rn = parallel_series(Rm2, Rl);
Rmkt = multiply_series(Rn, divide_series(Rpr_mkt, Rpr_tgt));

plot(pe10(1,:)/12, pe10(2,:), Rn(1,:)/12, Rn(2,:)./12, Rmkt(1,:)/12, Rmkt(2,:)./12, Rl(1,:)/12, Rl(2,:)/12, Rm2(1,:)/12, Rm2(2,:)/12, recessions(1,:)/12, 90*recessions(2,:));
legend("S&P 500 P/E Ratio (past 10 year, moving earnings)", "Estimated Real Estate P/E Ratio", "Median Home Sales Price/Target Ratio (normalized in 2016)", "Morgage Upper Bound", "location", "southeast");
axis([1970, 2022, 0, 90]);
%plot(Rpr_tgt(1,:)/12, Rpr_tgt(2,:), Rpr_mkt(1,:)/12, Rpr_mkt(2,:));
rent_apr(:,1:500) = [];
%plot(mort30us(1,:)/12, mort30us(2,:), rent_apr(1,:)/12, rent_apr(2,:), Gl_apr(1,:)/12, Gl_apr(2,:))
