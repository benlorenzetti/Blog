clear;
clc;
% Import FRED CSV Data (should be month timescale)
cpi=csvread('C:\Economic-Data\consumer-price-inflation-index.csv');
debt=csvread('C:\Economic-Data\federal-debt.csv');
money=csvread('C:\Economic-Data\federal-reserve-total-assets.csv');
gini=csvread('C:\Economic-Data\gini-ratio.csv');
gdp=csvread('C:\Economic-Data\nominal-gdp.csv');
trade=csvread('C:\Economic-Data\trade-balance-of-payments.csv');
housing=csvread('C:\Economic-Data\us-national-home-price-index.csv');
stocks=csvread('C:\Economic-Data\sp500.csv');
pop=csvread('C:\Economic-Data\population.csv');

% Remove Title Row
cpi(1,:)=[];    % coefficient
debt(1,:)=[];   % millions
money(1,:)=[];  % millions
gini(1,:)=[];   % mantissa
gdp(1,:)=[];    % billions
trade(1,:)=[];  % millions
housing(1,:)=[];% coefficient
stocks(1,:)=[]; % coefficient
pop(1,:)=[];    % thousands

% Match Dollars
gdp=[gdp(:,1),gdp(:,2)*1000]; % millions of dollars
pop=[pop(:,1),pop(:,2)/1000]; % millions of people

% Convert Year/Month Complex Numbers to Real year/decimal
x=real(cpi(:,1))-(1/12)*imag(cpi(:,1));
y=real(cpi(:,2));
cpi=[x,y];
x=real(debt(:,1))-(1/12)*imag(debt(:,1));
y=real(debt(:,2));
debt=[x,y];
x=real(money(:,1))-(1/12)*imag(money(:,1));
y=real(money(:,2));
money=[x,y];
x=real(gini(:,1))-(1/12)*imag(gini(:,1));
y=real(gini(:,2));
gini=[x,y];
x=real(gdp(:,1))-(1/12)*imag(gdp(:,1));
y=real(gdp(:,2));
gdp=[x,y];
x=real(trade(:,1))-(1/12)*imag(trade(:,1));
y=real(trade(:,2));
trade=[x,y];
x=real(housing(:,1))-(1/12)*imag(housing(:,1));
y=real(housing(:,2));
housing=[x,y];
x=real(stocks(:,1))-(1/12)*imag(stocks(:,1));
y=real(stocks(:,2));
stocks=[x,y];
x=real(pop(:,1))-(1/12)*imag(pop(:,1));
y=real(pop(:,2));
pop=[x,y];

% Plot All
subplot(5,2,1)
plot(cpi(:,1),cpi(:,2))
title("CPI Index (Coefficient)")
subplot(5,2,2)
plot(gini(:,1),gini(:,2))
title("Gini Coefficient (Mantissa)")
subplot(5,2,3)
semilogy(gdp(:,1),gdp(:,2))
title("GDP (Millions)")
subplot(5,2,4)
semilogy(debt(:,1),debt(:,2))
title("Federal Debt (Millions)")
subplot(5,2,5)
semilogy(money(:,1),money(:,2))
title("Federal Reserve Total Assets (Millions)")
subplot(5,2,6)
semilogy(trade(:,1),trade(:,2))
title("Balance of Trade (Millions)")
subplot(5,2,7)
semilogy(housing(:,1),housing(:,2))
title("National Home Price Index")
subplot(5,2,8)
semilogy(stocks(:,1),stocks(:,2))
title("S&P 500")
subplot(5,2,9)
semilogy(pop(:,1),pop(:,2))
title("US Population (Millions)")