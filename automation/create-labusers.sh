#!/bin/sh

set -eu

# Seat layout (matches the seat map on the workshop slide):
#   ROWS rows of tables; SEATS_PATTERN = seats per column, left to right.
#   The room alternates 2- and 4-seat tables, so columns are 2,4,2,4.
#   Tables are numbered left-to-right, top-to-bottom: T1 .. T(ROWS*COLS).
#   Username encodes the seat so each attendee can find theirs:
#     labuser-t<table>-s<seat>   (a 2-seat table only has s1,s2)
# Defaults: 5 rows x (2,4,2,4) = 60 seats.
ROWS="${ROWS:-5}"
SEATS_PATTERN="${SEATS_PATTERN:-2,4,2,4}"
DEFAULT_PASSWORD="${DEFAULT_PASSWORD:-***REDACTED***}"
# Whether lab users are platform admins. Granting admin to every attendee is
# convenient for a sandbox but risky on a shared/long-lived instance. Override
# with ADMIN=false to create non-admin users.
ADMIN="${ADMIN:-true}"
# Target JFrog server. Set SERVER to a configured server-id (see `jf c show`)
# so users are created on the intended instance instead of the CLI default.
SERVER="${SERVER:-}"

if ! command -v jf >/dev/null 2>&1; then
  echo "Missing JFrog CLI binary 'jf' in PATH." >&2
  exit 1
fi

if [ -z "$SERVER" ]; then
  echo "Set SERVER to the workshop server-id, e.g. SERVER=demo $0" >&2
  echo "Configured servers:" >&2
  jf c show 2>/dev/null | grep -i "Server ID" >&2 || true
  exit 1
fi

# Parse the per-column seat pattern into positional params ($1=col1, $2=col2, ...).
old_ifs="$IFS"; IFS=','; set -- $SEATS_PATTERN; IFS="$old_ifs"
COLS=$#

tmp_csv="$(mktemp "${TMPDIR:-/tmp}/labusers.XXXXXX.csv")"
trap 'rm -f "$tmp_csv"' EXIT

printf "username,password,email,admin\n" > "$tmp_csv"

count=0
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
      printf "%s,%s,%s,%s\n" \
        "${username}" "${DEFAULT_PASSWORD}" "${username}@example.com" "${ADMIN}" >> "$tmp_csv"
      count=$((count + 1))
      seat=$((seat + 1))
    done
    col=$((col + 1))
  done
  row=$((row + 1))
done

echo "Creating ${count} lab users on '${SERVER}' (${ROWS} rows x columns [${SEATS_PATTERN}], admin=${ADMIN})..."
jf rt users-create --server-id "$SERVER" --csv "$tmp_csv" --replace
echo "Done."
