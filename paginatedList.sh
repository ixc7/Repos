#!/usr/local/bin/bash

source "$(dirname ${0})/scrollableList.sh"

_paginatedList() {
  declare -a items="("${@}")"
  declare -a pages=()
  max=$(tput lines) # decrease by 1?
  pageCount=0
  outfile=""

  _parseArgs() {
    while [[ ${#*} -gt 0 ]]; do
      case ${1} in
      -o | --outfile)
        shift
        outfile="${1}"
        shift
        ;;
      *)
        items+=("${1}")
        shift
        ;;
      esac
    done
  }

  _parseArgs "${@}"

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

    _scrollableList "${temp[@]}" -o "${outfile}" &&
      selection="$(cat ${outfile})"

    [[ ${#selection} -gt 0 ]] &&
      break
  done
}
