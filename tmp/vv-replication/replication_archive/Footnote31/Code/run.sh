
#!/bin/bash

count=1

gcc -o rand Code/tstrand.c

seeds=`./rand 12345 20000`

arr=($seeds)
					
while [ ${count} -le 20 ]
do
        sbatch --mem=1g -t 00-05:00:00 --wrap="stata-se -b do Code/bootstrap_overID_CRC.do ${count} ${arr[$count]}"
        count=`expr $count + 1`
done
