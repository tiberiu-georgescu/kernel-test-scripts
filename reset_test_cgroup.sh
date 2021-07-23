#!/bin/bash

SWAPPINESS=60
LIMIT_IN_BYTES=4G

while getopts ":s:l:" arg; do
  case $arg in
    s) SWAPPINESS=$OPTARG;;
    l) LIMIT_IN_BYTES=$OPTARG;;
  esac
done

cgdelete -g memory:examples
cgcreate -g memory:examples
cgset -r memory.swappiness=$SWAPPINESS examples
cgset -r memory.limit_in_bytes=$LIMIT_IN_BYTES examples

cgget -r memory.swappiness -r memory.limit_in_bytes -r memory.usage_in_bytes examples
