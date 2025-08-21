#!/usr/bin/env bash

set -euo pipefail

# source your parser
. ./parser.sh

# helper for asserting
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

# --- Tests ---

# Test 1: single short flag
A=""
MATCHED_OPTS=()
parse -a:0 --- -a
assert_eq "a" "${MATCHED_OPTS[*]}" "single short option"
assert_eq "1" "${A:-1}" "short option sets variable"

# Test 2: short option with arg
XVAL=""
MATCHED_OPTS=()
parse -x:1 XVAL --- -x foo
assert_eq "x" "${MATCHED_OPTS[*]}" "short option with arg"
assert_eq "foo" "$XVAL" "short option arg captured"

# Test 3: clustered short options -ax
A=""; XVAL=""
MATCHED_OPTS=()
parse -a:0 -x:1 XVAL --- -ax bar
assert_eq "a x" "${MATCHED_OPTS[*]}" "clustered short options"
assert_eq "bar" "$XVAL" "clustered option arg"

# Test 4: long option with args
SRC=""; DEST=""
MATCHED_OPTS=()
parse --update:2 SRC DEST --- --update src.txt dest.txt
assert_eq "update" "${MATCHED_OPTS[*]}" "long option with args"
assert_eq "src.txt" "$SRC" "long opt arg1"
assert_eq "dest.txt" "$DEST" "long opt arg2"

# Test 5: positional args
P1=""; P2=""
MATCHED_OPTS=()
parse pos:2 P1 P2 --- foo bar
assert_eq "" "${MATCHED_OPTS[*]}" "no options"
assert_eq "foo" "$P1" "positional arg1"
assert_eq "bar" "$P2" "positional arg2"

echo "All tests passed ✅"
