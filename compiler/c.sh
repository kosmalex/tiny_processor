#!/bin/bash

read -e -p "File name: " name 
read -e -p "Format: " format 
echo ""
python3 c.py $name -f $format
