#!/bin/bash

BATCHDIR=$(dirname "$(readlink -f "$0")")
QUERY="DELETE FROM Colonna.jobmichele;"

${BATCHDIR}/query.sh "${QUERY}"