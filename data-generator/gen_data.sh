#!/bin/bash

g++ -DLOCAL -O3 -std=c++20 -static $1.cpp -o $1

./$1 > $2

rm $1