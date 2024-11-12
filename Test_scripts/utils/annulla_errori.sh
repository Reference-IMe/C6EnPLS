#!/bin/bash

for err in $(./search_error.sh)
do
	 > ${err}
done
