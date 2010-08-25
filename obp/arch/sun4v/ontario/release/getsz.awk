BEGIN {start = 0; sum = 0}
{
for (i = 1; i <= NF ; i++) {
  if ($i == "text") {
    start = 1;
    sum = $(i-1);
  }
  if (start) { 
    if ((i % 2) == 1) sum = sum + $i;
  }
  if ($i == "data") {
    start = 0;
    printf "%d\n",sum;
  }
}
}
