# Verification report: regenerated vs canonical analysis datasets

Primary verdict is the Stata datasignature (content equality, order-independent).
cf _all is a secondary positional check (rc 0 means identical position by position).

## CHN
- obs (regenerated / canonical): 143252 / 143252
- unique pid (regenerated / canonical): 50965 / 50965
- datasignature regenerated: 143252:39(98939):877911726:3678686200
- datasignature canonical:   143252:39(98939):877911726:3678686200
- VERDICT: datasignature MATCH --- data content identical
- variable list: identical
- cf _all: identical position by position (rc 0)

## IDN
- obs (regenerated / canonical): 118828 / 118828
- unique pid (regenerated / canonical): 44517 / 44517
- datasignature regenerated: 118828:53(74608):3185622185:2951742591
- datasignature canonical:   118828:53(74608):3185622185:2951742591
- VERDICT: datasignature MATCH --- data content identical
- variable list: identical
- cf _all: identical position by position (rc 0)

## TZA
- obs (regenerated / canonical): 34598 / 34598
- unique pid (regenerated / canonical): 15673 / 15673
- datasignature regenerated: 34598:42(60961):1203211533:418565794
- datasignature canonical:   34598:42(60961):1203211533:418565794
- VERDICT: datasignature MATCH --- data content identical
- variable list: identical
- cf _all: identical position by position (rc 0)

## Nominal vs real probe (read-only)
- CHN mean consumption --- nominal 55337.74448781476, real 47572.26712508257, real_spatial 46924.65118797401
- IDN mean consumption --- nominal 231495.7751793841, real 866560.5909854728, real_spatial 337914.7763631847

