#!/usr/local/bin/bash

_paginateArray() {
  declare -a items="("${@}")"
  declare -a pages=()

  max=$(tput lines)

  ns
  echo -e "original:\n${items[@]}\n${#items[@]} items\n"

  pageCount=0
  while true; do
    if [[ ${#items[@]} -eq 0 ]]; then
      break
    else
      pages[pageCount]="${items[@]:0:${max}}"
      pageCount=$((pageCount + 1))
      items=(${items[@]:${max}})
    fi
  done

  for i in "${!pages[@]}"; do
    declare -a temp="(${pages[i]})"
    echo -e "page $((i + 1))/${#pages[@]}:\n${temp[@]}\n${#temp[@]} items\n"
  done
}

_paginateArray "$(seq 300)"
