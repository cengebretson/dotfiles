#!/usr/bin/env bash

# shellcheck disable=SC2034  # variables accessed via indirect expansion ${!varname}
format_hide=""
format_none="0123456789"
format_fsquare="󰎡󰎤󰎧󰎪󰎭󰎱󰎳󰎶󰎹󰎼"
format_hsquare="󰎣󰎦󰎩󰎬󰎮󰎰󰎵󰎸󰎻󰎾"
format_dsquare="󰎢󰎥󰎨󰎫󰎲󰎯󰎴󰎷󰎺󰎽"
format_msquare="󰼎󰼏󰼐󰼑󰼒󰼓󰼔󰼕󰼖󰼗"
format_super="⁰¹²³⁴⁵⁶⁷⁸⁹"
format_sub="₀₁₂₃₄₅₆₇₈₉"

ID=$1
FORMAT=${2:-none}

varname="format_${FORMAT}"
format="${!varname}"

if [ "$FORMAT" = "hide" ]; then
  exit 0
fi

if [ -z "$format" ]; then
  echo "Invalid format: $FORMAT"
  exit 1
fi

for ((i = 0; i < ${#ID}; i++)); do
  DIGIT=${ID:i:1}
  echo -n "${format:DIGIT:1} "
done
