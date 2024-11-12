#!/bin/bash

BATCHDIR=$(dirname "$(readlink -f "$0")")
QUERY="DELETE FROM Colonna.forecast;"

${BATCHDIR}/query.sh "${QUERY}"
