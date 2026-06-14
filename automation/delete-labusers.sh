#!/bin/sh

set -eu

# Must match the layout used by create-labusers.sh.
ROWS="${ROWS:-5}"
SEATS_PATTERN="${SEATS_PATTERN:-2,4,2,4}"
SERVER="${SERVER:-}"

if ! command -v jf >/dev/null 2>&1; then
  echo "Missing JFrog CLI binary 'jf' in PATH." >&2
  exit 1
fi

if [ -z "$SERVER" ]; then
  echo "Set SERVER to the workshop server-id, e.g. SERVER=demo $0" >&2
  exit 1
fi

old_ifs="$IFS"; IFS=','; set -- $SEATS_PATTERN; IFS="$old_ifs"
COLS=$#

users=""
table=0
row=1
while [ "$row" -le "$ROWS" ]; do
  col=1
  while [ "$col" -le "$COLS" ]; do
    table=$((table + 1))
    eval "seats=\${$col}"
    seat=1
    while [ "$seat" -le "$seats" ]; do
      username="labuser-t${table}-s${seat}"
      if [ -z "$users" ]; then
        users="${username}"
      else
        users="${users},${username}"
      fi
      seat=$((seat + 1))
    done
    col=$((col + 1))
  done
  row=$((row + 1))
done

jf rt users-delete --server-id "$SERVER" --quiet "${users}" || true
echo "Deleted (or already missing) on '${SERVER}': ${users}"
