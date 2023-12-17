#!/usr/local/bin/bash

source './env.sh'
source './scrollableList.sh'

# get input 
[[ ${#*} -gt 0 ]] && 
  q="${@}" ||
  while [[ ${#q} -eq 0 ]]; do
    read -p "search: " q
  done

runSearch () {
  gh search repos \
    --sort "stars" \
    --limit "${maxHeight}" \
    --json "${json}" \
    --jq '.[].fullName' \
    "${@}"
}

[[ ${#q} -gt 0 ]] && 
  declare -a searchResults="($(runSearch ${q}))"

[[ ${#searchResults[@]} -eq 0 ]] && 
  echo "no results" && 
  exit 1

tempfile=$(mktemp)

while true; do
  selection="" 

  _scrollableList "${searchResults[@]}" -o "${tempfile}" &&
    selection=$(cat "${tempfile}")

  [[ "${#selection}" -eq 0 ]] &&
    break ||
    gh repo view "${selection}" | ${pager}
done

