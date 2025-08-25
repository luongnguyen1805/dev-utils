#!/usr/bin/env bash

set -euo pipefail

# --- source your parser implementation ---
. ./parser.sh

# --- helper for asserting ---
assert_eq() {
  local expected=$1
  local actual=$2
  local msg=$3
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $msg"
  else
    echo "FAIL: $msg (expected '$expected', got '$actual')" >&2
    exit 1
  fi
}

# helper to run parser with standard spec
run_parse() {  
  local SPEC="--update:2 SRC DST --allow:0 -n:0 -z:0 \
    -p--pass:2 P1 P2 -x:1 X1 -c:3 C1 C2 C3 pos:2 D1 D2"  
  parse $SPEC --- "$@"
}

# --- Tests ---

# Test 1: single short flag
run_parse -n foo bar
assert_eq "foo" "$D1" "positional 1 assigned"
assert_eq "bar" "$D2" "positional 2 assigned"
assert_eq "n" "${MATCHED_OPTS[0]}" "matched option recorded"

# Test 2: clustered short flags
run_parse -nz foo bar
assert_eq "n" "${MATCHED_OPTS[0]}" "matched_opts includes n"
assert_eq "z" "${MATCHED_OPTS[1]}" "matched_opts includes z"

# Test 3: long flag --allow
run_parse --allow foo bar
assert_eq "allow" "${MATCHED_OPTS[0]}" "matched_opts includes allow"

# Test 4: option with args --update
run_parse --update src.txt dst.txt foo bar
assert_eq "src.txt" "$SRC" "SRC assigned"
assert_eq "dst.txt" "$DST" "DST assigned"
assert_eq "update" "${MATCHED_OPTS[0]}" "matched_opts includes update"

# Test 5: option alias -p
run_parse -p secret pass extra1 extra2
assert_eq "secret" "${P1}" "-p arg1 assigned"
assert_eq "pass" "${P2}" "-p arg2 assigned"
assert_eq "extra1" "${D1}" "pos1 assigned"
assert_eq "extra2" "${D2}" "pos2 assigned"
assert_eq "p" "${MATCHED_OPTS[0]}" "matched_opts includes p"

# Test 6: option alias --pass
run_parse --pass s1 s2 foo bar
assert_eq "s1" "${P1}" "--pass arg1 assigned"
assert_eq "s2" "${P2}" "--pass arg2 assigned"
assert_eq "pass" "${MATCHED_OPTS[0]}" "matched_opts includes pass"

# Test 7: option with 1 arg -x
run_parse -x value foo bar
assert_eq "value" "${X1}" "-x arg assigned"
assert_eq "x" "${MATCHED_OPTS[0]}" "matched_opts includes x"

# Test 8: option with 3 args -c
run_parse -c a b c foo bar
assert_eq "a" "${C1}" "C1 assigned"
assert_eq "b" "${C2}" "C2 assigned"
assert_eq "c" "${C3}" "C3 assigned"
assert_eq "c" "${MATCHED_OPTS[0]}" "matched_opts includes c"

# Test 9: multiple options together
run_parse --update A B -p X Y -c c1 c2 c3 baz qux
assert_eq "A" "${SRC}" "SRC assigned"
assert_eq "B" "${DST}" "DST assigned"
assert_eq "X" "${P1}" "P1 assigned"
assert_eq "Y" "${P2}" "P2 assigned"
assert_eq "c1" "${C1}" "C1 assigned"
assert_eq "c2" "${C2}" "C2 assigned"
assert_eq "c3" "${C3}" "C3 assigned"
assert_eq "baz" "${D1}" "D1 assigned"
assert_eq "qux" "${D2}" "D2 assigned"

echo "✅ All tests passed."
