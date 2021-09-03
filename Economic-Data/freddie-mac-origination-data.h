#ifndef FREDDIE_MAC_ORIGINIATION_DATA_H
#define FREDDIE_MAC_ORIGINIATION_DATA_H
#include <stdlib.h>
#include <string.h>
/*
Copyright (c) 2021 Ben Lorenzetti

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 *
 * freddie_filename(dest, path, qtr) produces the standardized filename for
 * the Freddie Mac Single-Familiy Loan-Level Dataset and allows easy file path
 * concatenation, which is necessary because the datasets have to be kept for
 * internal use only due to the Terms and Conditions for Use.
 */
char* freddie_filename(char*, const char*, int);
/*
 * read_line(dest, src) - helper function to read a line from the src file,
 * remove the '\n', and return the number of bytes read or 0 if empty or EOF.
 */
int read_line(char*, FILE*);
/*
 * parse_freddie_loan_line(src) takes a Cstring with the '\n' character
 * already removed and returns the data structure below. Success is
 * indicated by a checksum of 0.
 */
typedef struct loan_record loan_record;
loan_record parse_freddie_loan_line(const char*);

#define FMT1TO4 "%d|%d|%c|%d%n" // 5 can be null -> handle manually
#define FMT6TO10 "%d|%d|%c|%d|%d|%n"
#define FMT11TO15 "%d|%d|%f|%c|%c|%n"
#define FMT16TO18 "%cRM|%2s|%2s%n" // 19 can be null -> handle manually
#define FMT20TO23 "%12s|%c|%3d|%2d|%n"
struct loan_record {
  int checksum;      // 0.  Returns 0 for valid checksum or item of failure.
  int credit_score;  // 1.  301-850 or 9999 (not available (N/A))
  int yyyymm_start;  // 2.  first payment date
  char first_flag;   // 3.  Y, N, or 9 N/A (not available)
  int yyyymm_end;    // 4.  Maturity Date
  int msa_code;      // 5.  5-Digit MSA code or 5 spaces if unknown
  int insurance_pct; // 6.  % 0-55% or 999 N/A
  int units;         // 7.  1-4 number of units or 99 N/A
  char occ_flag;     // 8.  P, S, I for primary, 2nd, investment home or 9 N/A
  int CLTV;          // 9.  combined loan to value % or 999 not available (N/A)
  int DTI;           // 10. 0-65% debt to income ratio or 999 N/A
  int principal;     // 11. Initial principal
  int LTV;           // 12. Loan pricipal to value % or 999 N/A not available
  float intr;        // 13. Interest Rate
  char channel_flag; // 14. R,B,C,T,9
  char ppm_flag;     // 15. Y or N prepayment mortgage penalty
  char amor_flag;    // 16. F fixed rate or A adjustable rate
  char state[4];     // 17. "OH" for Ohio
  char type[4];      // 18. "CO", "PU", "MH", "SF", "CP", for Condo, PUD
                     // Manufactured home, Single family and Co-op or 99 N/A
  int zip_code;      // 19. first 3 digits of zip code or 0 not available
  char loan_id[16];  // 20. Unique identifier
  char purpose_flag; // 21. P purchase, C refinance cash out, N refi. no cash
                     // cash out, R refi. not specified, or 9 N/A not available
  int loan_term;     // 22. Loan term in months
  int num_borrowers; // 23. 1, 2, or 99 (not available or > 2)
  char seller[64];   // 24. Seller name or "Other Sellers"
  char servicer[64]; // 25. Servicer name or "Other Services"
  char conf_flag;    // 26. Y or 0, Super conforming flag
  char preharpid[16];// 27. 12 char pre-HARP loan seq number or 0
  char prog_flag;    // 28. H or 9 for "home possible advantage" or not.
  char harp_flag;    // 29  Y or 0.
  char val_method;   // '1', '2', '3', or '9'
  char intonly_flag; // 'Y' or 'N'
};

/*
 * IMPLEMENTATION
 */

 char* freddie_filename(char* dest, const char* path, int qtr) {
   strcat(strcpy(dest, path), "historical_data_");
   sprintf(dest+strlen(dest), "%d", (qtr-1)/4+1);
   char qtr_char = (qtr-1)%4 + '1';
   strcat(strncat(strcat(dest, "Q"), &qtr_char, 1), ".txt");
   return dest;
 }

loan_record parse_freddie_loan_line(const char* data_line) {
  loan_record ret;
  int n = 0;
  const char* data = data_line;
  ret.checksum = sscanf(data, FMT1TO4, &ret.credit_score,
    &ret.yyyymm_start, &ret.first_flag, &ret.yyyymm_end, &n);
  data += n;
  if(data[1] == '|')
    ret.msa_code = 0, ret.checksum++, data += 2;
  else {
    ret.checksum += sscanf(data, "|%d|%n", &ret.msa_code, &n);
    data += n;
  }
  ret.checksum = ret.checksum + sscanf(data, FMT6TO10, &ret.insurance_pct,
    &ret.units, &ret.occ_flag, &ret.CLTV, &ret.DTI, &n);
  data += n;
  ret.checksum += sscanf(data, FMT11TO15, &ret.principal,
    &ret.LTV, &ret.intr, &ret.channel_flag, &ret.ppm_flag, &n);
  data += n;
  ret.checksum += sscanf(data, FMT16TO18, &ret.amor_flag, ret.state, ret.type, &n);
  ret.state[2] = 0;
  ret.type[2] = 0;
  data += n;
  if(data[1] == '|')
    ret.zip_code = 0, ret.checksum++, data += 2;
  else {
    ret.checksum += sscanf(data, "|%d|%n", &ret.zip_code, &n);
    data += n;
  }
  ret.checksum += sscanf(data, FMT20TO23, ret.loan_id, &ret.purpose_flag,
    &ret.loan_term, &ret.num_borrowers, &n);
  ret.loan_id[13] = 0;
  data += n;
  if(ret.checksum != 23)
    return ret;
  // Field 24
  ret.checksum = 24;
  const char* delim_end = strchr(data, '|');
  if(!delim_end || delim_end - data > 60)
    return ret;
  strncpy(ret.seller, data, delim_end - data);
  ret.seller[delim_end-data] = 0;
  data = delim_end + 1;
  // Field 25
  ret.checksum = 25, delim_end = strchr(data, '|');
  if(!delim_end || delim_end - data > 60)
    return ret;
  strncpy(ret.servicer, data, delim_end - data);
  ret.servicer[delim_end-data] = 0;
  data = delim_end + 1;
  // Field 26 Super conforming flag
  ret.checksum = 26;
  if(*data != '|' && *data != 'Y' && *data != ' ')
    return ret;
  if(*data == '|')
    ret.conf_flag = 0, data++;
  else
    ret.conf_flag = *data, data += 2;
  // Field 27
  ret.checksum = 27;
  delim_end = strchr(data, '|');
  strncpy(ret.preharpid, data, delim_end - data);
  ret.preharpid[delim_end-data] = 0;
  data = delim_end + 1;
  // Field 28
  ret.checksum = 28;
  if(data[0] != 'H' && data[0] != '9')
    return ret;
  ret.prog_flag = data[0], data += 2;
  // Field 29 HARP flag
  ret.checksum = 29;
  if(data[0] != '|' && data[0] != 'Y')
    return ret;
  if(data[0] == '|')
    ret.harp_flag = 0, data++;
  else
    ret.harp_flag = *data, data += 2;
  // Field 30
  ret.checksum = 30;
  if(*data != '1' && *data != '2' && *data != '3' && *data != '9')
    return ret;
  ret.val_method = data[0], data += 2;
  // Field 31
  ret.checksum = 31;
  if(data[0] != 'N' && data[0] != 'Y')
    return ret;
  ret.intonly_flag = data[0], data += 2;

  ret.checksum = 0;
  return ret;
}

int read_line(char* dest, FILE* src) {
  char* d = dest;
  char s = fgetc(src);
  if(s != EOF && s != '\n')
  do {
    *(d++) = s;
    s = fgetc(src);
  } while(s != '\n');
  d[0] = 0;
  return d - dest;
}

#endif
