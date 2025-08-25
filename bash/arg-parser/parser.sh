#!/usr/bin/env bash

set -euo pipefail

parse() {
  local -A opt_counts=()
  local -A opt_vars=()
  local -a pos_vars=()
  local -a matched_opts=()

  # --- 1. read spec ---
  while [[ $# -gt 0 ]]; do
    case $1 in
      ---) shift; break ;;
      -*:*)
        local opt=${1%%:*}        # e.g. "-p"    
        local long=
        if [[ $opt == -*--* ]]; then
          short="${opt%%--*}"   # take everything before first `--`
          short="${short#-}"    # strip leading "-"

          long="--${opt#*--}"     # take everything after `--`
          opt="-$short"
        fi
           
        local count=${1##*:}
        shift
        local vars=()
        for ((i=0; i<count; i++)); do
          vars+=("$1"); shift
        done

        opt_counts[$opt]=$count
        opt_vars[$opt]="${vars[*]}"

        if [[ -n $long ]]; then
          opt_counts[$long]=$count
          opt_vars[$long]="${vars[*]}"
        fi

        ;;
      pos:*)
        local count=${1##*:}
        shift
        for ((i=0; i<count; i++)); do
          pos_vars+=("$1"); shift
        done
        ;;
      *)
        echo "Bad Spec $1" >&2
        return 1
        ;;
    esac
  done

  # --- 2. parse argv ---
  local -a remaining=()
  while [[ $# -gt 0 ]]; do
    local arg=$1; shift

    if [[ ${opt_counts[$arg]+_} ]]; then
      # exact match (short or long)
      matched_opts+=("${arg##*-}")   # strip ALL leading dashes
      local count=${opt_counts[$arg]}
      if (( count > $# )); then
        echo "Invalid Arguments for Option $arg" >&2
        return 1
      fi
      if (( count > 0 )); then
        local vars=(${opt_vars[$arg]})
        for ((i=0; i<count; i++)); do
          declare -n ref=${vars[$i]}
          ref=$1
          shift
        done
      fi

    elif [[ $arg == -* && ${#arg} -gt 2 && $arg != --* ]]; then
      # clustered short options like -ax (but not --long)
      for ((j=1; j<${#arg}; j++)); do
        local short="-${arg:j:1}"
        if [[ ${opt_counts[$short]+_} ]]; then
          matched_opts+=("${short##*-}")
          local count=${opt_counts[$short]}
          if (( count > $# )); then
            echo "Invalid Arguments for Option $short" >&2
            return 1
          fi
          if (( count > 0 )); then
            local vars=(${opt_vars[$short]})
            for ((i=0; i<count; i++)); do
              declare -n ref=${vars[$i]}
              ref=$1
              shift
            done
          fi
        else
          echo "Invalid Option $short" >&2
          return 1
        fi
      done

    elif [[ $arg == -* ]]; then
      # unknown long option
      echo "Invalid Option $arg" >&2
      return 1

    else
      remaining+=("$arg")
    fi
  done

  # --- 3. assign positional vars ---
  for i in "${!pos_vars[@]}"; do
    if [[ -n ${remaining[$i]:-} ]]; then
      declare -n ref=${pos_vars[$i]}
      ref=${remaining[$i]}
    fi
  done

  # --- 4. return matched options ---
  MATCHED_OPTS=("${matched_opts[@]}")
}

# ===== Example usage =====

# P1= P2= X1=
# C1= C2= C3=
# D1= D2=
# SRC= DST=
# MATCHED_OPTS=()

# parse --update:2 SRC DST --allow:0 -n:0 -z:0 -p--pass:2 P1 P2 -x:1 X1 -c:3 C1 C2 C3 pos:2 D1 D2 --- "$@"
# parse \
#   --update:2 SRC DST \
#   --allow:0 \
#   -n:0 \
#   -z:0 \
#   -p--pass:2 P1 P2 \
#   -x:1 X1 \
#   -c:3 C1 C2 C3 \
#   pos:2 D1 D2 \
#   --- "$@"

# echo "P1=$P1 P2=$P2 X1=$X1"
# echo "C1=$C1 C2=$C2 C3=$C3"
# echo "D1=$D1 D2=$D2"
# echo "SRC=$SRC DST=$DST"
# echo "Matched opts: ${MATCHED_OPTS[*]}"

# ./parser.sh -zn --allow  --update Alice Bob foo bar