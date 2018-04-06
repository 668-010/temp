#!/bin/bash

mountlist=$(cat /etc/fstab | sed '/^#\|^$/d' | grep -v "#nomonitor" | grep -v "nofail" | awk '{print $2}')

if echo $mountlist | grep $1 > /dev/nul
then echo 0
else echo 1
fi