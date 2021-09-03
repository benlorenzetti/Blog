#include <stdio.h>
#include <assert.h>
#include "freddie-mac-origination-data.h"

typedef struct month_summary {
  int loan_count;
  double ave_down;
} month_summary;

int process_qtr(month_summary*, FILE*, int(*)(loan_record));

int filter(loan_record r) {
  return r.harp_flag == 'Y'
    || r.amor_flag == 'A'
    || r.LTV < 6 || r.LTV > 105
    || r.loan_term != 360;
}

int main(int argc, char* argv[]) {
  // 1. Get command line inputs for which files to process
  if(argc != 4) {
    printf("Usage: %s \"1999Q1\" \"2000Q3\" \"C:\\Data\\\" \n", argv[0]);
    exit(0);
  }
  char range_str[8];
  int year_start = atoi(strncpy(range_str, argv[1], 4));
  int year_end = atoi(strncpy(range_str, argv[2], 4));
  int first_qtr = 4*(year_start-1) + argv[1][5] - '0';
  int last_qtr = 4*(year_end-1) + argv[2][5] - '0';

  // 2. Iterate over the Data
  char fname[1024];
  month_summary months[1024] = {0};
  int i = 0;
  assert(first_qtr <= last_qtr);
  do {
    // 1. Open Data File
    FILE* fp = fopen(freddie_filename(fname, argv[3], first_qtr + i), "r");
    if(!fp)
      printf("Error: %s not found\n", fname), exit(0);
    printf("%s: ... ", fname);
    // 2. Process One Qtr of Data
    int lines = process_qtr(months + i*3, fp, &filter);
    printf(" %7d ", lines);
    printf("%6d %6d %6d ", months[i*3].loan_count, months[i*3+1].loan_count, months[i*3+2].loan_count);
    printf("%.2f %.2f %.2f\n", months[i*3].ave_down, months[i*3+1].ave_down, months[i*3+2].ave_down);
    // 3. Close Data File
    fclose(fp);
  } while (++i <= last_qtr - first_qtr);

  // 3. Output Results
  strcat(strcpy(fname, argv[3]), "pct-down.csv");
  FILE* fp = fopen(fname, "w");
  fprintf(fp, "DATE,PCT-DOWN");
  i = 0;
  int end = 3 * (1 + last_qtr - first_qtr);
  do {
    int yr = 1 + (first_qtr - 1 + i/3)/4;
    int month = (3*(first_qtr-1) + i) % 12 + 1;
    fprintf(fp, "\n%4.d-%2.2d-01,%.2f", yr, month, months[i].ave_down);
  } while(++i < end);
  fclose(fp);
}

int process_qtr(month_summary* months, FILE* fp, int(*filter)(loan_record)) {
  char line[2048];
  long long int line_count = 0;
  long long int pct_down_sum[3] = {0, 0, 0};
  while(read_line(line, fp)) {
    loan_record rec = parse_freddie_loan_line(line);
    if(rec.checksum) {
      printf("invalid checksum (%d): %s\n", rec.checksum, line);
      continue;
    }
    if(filter(rec))
      continue;
    line_count++;
    int month_index = (rec.yyyymm_start % 100 - 1) % 3;
    int pct_down = 100 - rec.LTV;
    months[month_index].loan_count += 1;
    pct_down_sum[month_index] += pct_down;
  }
  months[0].ave_down = pct_down_sum[0];
  months[0].ave_down /= months[0].loan_count;
  months[1].ave_down = pct_down_sum[1];
  months[1].ave_down /= months[1].loan_count;
  months[2].ave_down = pct_down_sum[2];
  months[2].ave_down /= months[2].loan_count;
  return line_count;
}
