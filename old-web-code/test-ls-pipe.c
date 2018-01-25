#include <stdio.h>
#include <stdlib.h>

int main()
{ 

  FILE *fp;
  char output[1024];

  fp = popen("/bin/ls *.c", "r");
  if (fp == NULL)
    exit(1);

  while (fgets(output, 1023, fp) != NULL) 
    printf("%s", output);

  pclose(fp);

  return 0;
}
