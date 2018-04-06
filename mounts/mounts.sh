#!/bin/bash

if df | grep $1 > /dev/nul
then echo 1
else echo 0
fi
