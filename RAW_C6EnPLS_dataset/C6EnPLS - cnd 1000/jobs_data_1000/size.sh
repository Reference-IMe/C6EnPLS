#!/bin/bash

for i in $( ls | xargs)
do
	if [[ $i != "size.sh" ]]; then
		SIZE=$(cat $i | wc -l )
		SIZE=$(( SIZE -1 ))
		echo $SIZE
	fi
done 
