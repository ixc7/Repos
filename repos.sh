#!/usr/local/bin/bash

pathname="$(dirname ${0})"

helpTxt="
  usage: $(basename ${0}) -h [QUERY...] 

  options:
      -h, --help        show help
      -c, --config      show config
"

source "${pathname}/env.sh"
source "${pathname}/scrollableList.sh"
source "${pathname}/util.sh"

parseArgs () {
  while [[ ${#*} -gt 0 ]]; do
    case ${1} in
      -h | --help)
        _showHelp "${helpTxt}" && exit 0
      ;;
      -c | --config)
        bat -pp "${pathname}/env.sh" && exit 0
      ;;
      *)
        shift 
      ;;
    esac
  done
}

# init
parseArgs "${@}"

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

