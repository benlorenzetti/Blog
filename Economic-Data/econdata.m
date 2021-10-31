% Copyright (c) 2021 Ben Lorenzetti
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

% Documentation available at: "snth.us/Econcomic-Data/matlab.html"

% Prevent Octave from thinking this is a single function file
% and shortens data file loadpaths:
warning('off', 'Octave:data-file-in-path');

function open_closed_range = oc_rng(series)
  if(size(series)(2) == 0)
    zero = 0;
    last = 0;
  else
    if(size(series)(2) == 1)
      zero = series(1,1) - 1;
    else
      zero = series(1,1) - (series(1,2) - series(1,1));
    endif
    last = series(1,size(series)(2));
  endif
  open_closed_range = [zero, last];
endfunction

function intersection_open_closed_range = int_rng(rng1, rng2)
  zero = max(rng1(1), rng2(1));
  last = min(rng1(2), rng2(2));
  intersection_open_closed_range = [zero, last];
endfunction

function TorF = isin(n, oc_range)
  TorF = (n > oc_range(1) & n <= oc_range(2));
endfunction

function stretched2monthly_data = s2m_data(data2byN)
  stretched2monthly_data = [];
  i = 0;
  iend = size(data2byN)(2);
  mprev = oc_rng(data2byN)(1);
  jsum = 0;
  jdiv = 0;
  while(i < iend)
    i = i + 1;
    m = data2byN(1,i);
    jsum = jsum + data2byN(2,i);
    jdiv = jdiv + 1;
    if(m == mprev && i != iend)
      continue;
    elseif(m == mprev + 1 || i == iend)
      mprev = m;
      stretched2monthly_data = [stretched2monthly_data, [m; jsum/jdiv]];

    else
      do 
        mprev = mprev + 1;
        stretched2monthly_data = [stretched2monthly_data, [mprev; jsum/jdiv]];
      until(mprev == m)
  endif
  jsum = 0;
  jdiv = 0;

  endwhile
endfunction

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
function dif = differentiate_series(s)
  dif(1,:) = s(1,2:size(s)(2));
  dif(2,:) = s(2,2:size(s)(2));
  left = s(2,1:size(s)(2)-1);
  dif(2,:) = (dif(2,:) .- left) ./ left;
endfunction

function new_index = normalize(index_data, real_data, year)
  irefpt = lookup(index_data(2,:), 12*year);
  rrefpt = lookup(real_data(2,:), 12*year);
  scale = real_data(2, rrefpt) / index_data(2, irefpt);
  new_index(1,:) = index_data(1,:);
  new_index(2,:) = index_data(2,:) * scale;
endfunction

function mave = moving_ave(data, last_n)
  first = data(1,last_n+1);
  last = data(1,size(data)(2));
  i = 0;
  do
    mave(1,i+1) = first + i;
    mave(2,i+1) = sum(data(2,i+1:i+last_n))/last_n;
    i = i + 1;
  until(i == last - first)
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
