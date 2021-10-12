% Prevent Octave from thinking this is a single function file
1;

function RN = Rmort(APR, N)
  mfr = (APR/100 + 1)^(1/12);
  if(APR == 0)
    RN = N;
  else
    RN = (1-mfr^(-N))/(1-mfr^(-1));
  endif
endfunction
function months = equity_buildup_time(n, APR, IPR, N)
  Rm = Rmort(APR, N);
  inf = realpow(1+IPR/100, 1/12);
  r = realpow(1+APR/100, 1/12);
  c1 = (r-inf)/(1-1/r);
  c2 = (r^(-N))/(1-1/r);
  months = n + c1*(c2*(r^n - 1) - n);
endfunction
function frac = equity_buildup_frac(n, f, L, APR, IPR, N)
  En = equity_buildup_time(n, APR, IPR, N);
  frac = 1 - 2*f*(L+1) + (L/Rmort(APR,N)) * En;
endfunction
function point = opt_brute(f, L, APR, IPR, N)
  i = opt_pt(f, L, APR, IPR, N)(1);
  prev = e_yield(i,f,L,APR,IPR,N) + x_yield(i,f,L,APR,IPR,N);
  do
    i = i + 1;
    val = e_yield(i,f,L,APR,IPR,N) + x_yield(i,f,L,APR,IPR,N);
  until(val <= prev | i == 360);
  point = other_pt(i, f, L, APR, IPR, N);
endfunction
function point = opt_pt(f, L, apr, ipr, N)
  Rm = Rmort(apr, N);
  months = (Rm/L)*(2*f*(L+1)+sqrt(2*f*(L+1)));
  point = other_pt(months, f, L, apr, ipr, N);
endfunction
function point = other_pt(n, f, L, apr, ipr, N)
  equity = equity_buildup_frac(n, f, L, apr, ipr, N);
  mfrac = equity^(1/n);
  apr_yield = 100*(mfrac^12 - 1);
  point = [n, equity, mfrac, apr_yield];
endfunction
function ext_yield = x_yield(n, f, L, APR, IPR, N, c)
  num = (L+1)*(1-f)/(c*L) - (1+IPR/100)^(-n/12);
  denom = 1 + (L/Rmort(APR,N))*equity_buildup_time(n,APR,IPR,N);
  ext_yield = (L/Rmort(APR,N))*num/denom;
endfunction
function int_yield = e_yield(n, f, L, APR, IPR, N)
  frac = equity_buildup_frac(n, f, L, APR, IPR, N);
  int_yield = frac^(1/n) - 1;
endfunction
function point = brute_opt(f, L, APR, IPR, N)
  i = floor(opt_pt(f, L, APR, IPR, N)(1));
  val = e_yield(i,f,L,APR,IPR,N);
  do
    prev = val;
    i = i + 1;
    val = e_yield(i,f,L,APR,IPR,N);
  until(val <= prev || i == 360);
  point = other_pt(i, f, L, APR, IPR, N);
endfunction
