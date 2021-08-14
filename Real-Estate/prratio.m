clear;
clc;
function data = import_fred_csv(filename)
  % Import FRED CSV Data (should be monthly or greater timescale)
  data=csvread(filename);
  % Remove Title Row
  data(1,:)=[];
  % Convert Year/Month Complex Numbers to month index
  data(:,1) = real(12*data(:,1))-imag(data(:,1));
endfunction

function array = stretch_align_index(data, start, stop) 
  m = 0;
  while(m <= stop - start)
    i = lookup(data(:,1), m+start);
    array(m+1) = data(i,2);
    m = m + 1;
  endwhile
endfunction

mort30us = import_fred_csv('C:\Economic-Data\MORTGAGE30US.csv');   % percent apr
mspus = import_fred_csv('C:\Economic-Data\MSPUS.csv');             % dollars
rent_index = import_fred_csv('C:\Economic-Data\CUUR0000SEHA.csv'); % unitless
recessions = import_fred_csv('C:\Economic-Data\JHDUSRGDPBR.csv');  % 0 or 1

start = max([mspus(1,1),mort30us(1,1),rent_index(1,1), recessions(1,1)]);
stop = min([max(mspus(:,1)), max(mort30us(:,1)), max(rent_index(:,1)), max(recessions(:,1))]);

yr = (start : stop)/12;
apr = stretch_align_index(mort30us,start,stop);
mpr = realpow(1 + apr./100, 1/12);
Rmort = (1-mpr.^(-360)) ./ (1 - 1./mpr);
Vmed = stretch_align_index(mspus,start,stop);
Irent = stretch_align_index(rent_index,start,stop);
Recess = stretch_align_index(recessions, start, stop);

Rreal = 180;
scale_refpoint = lookup(yr,2016);
Rth = (Rreal * Rmort)./(Rmort + Rreal);
scale = Vmed(scale_refpoint)/(Rth(scale_refpoint)*Irent(scale_refpoint));

plot(yr, Vmed./(scale*Irent), 'k', yr, Rth, 'r', yr, 70*Recess+40);
title("Median Sales Price to Rent Index");
legend("Median Sales Price P/R Index", "Limiting Dividend P/R Ratio", "US Recession", "location","southeast");
ylabel("months");
