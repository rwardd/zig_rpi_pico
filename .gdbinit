target remote localhost:3333
set radix 16
load
mon reset halt
b _start
