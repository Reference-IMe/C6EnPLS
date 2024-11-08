#!/bin/bash

BATCHDIR=$(dirname "$(readlink -f "$0")")
QUERY="SELECT * FROM Colonna.jobmichele;"

${BATCHDIR}/query.sh "$1" "${QUERY}"
