#!/bin/bash

trap 'rm -f "$TMPFILE"' EXIT

TMPFILE=$(mktemp) || exit 1
ls /etc > $TMPFILE
echo $TMPFILE
if grep -qi "kernel" $TMPFILE; then
  echo 'find'
fi
