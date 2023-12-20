#!/usr/local/bin/bash

pathname="$(dirname ${0})"

helpTxt="
  usage: $(basename ${0}) -h [QUERY...] 

  options:
      -h, --help        show help
"

source "${pathname}/previewFiles.sh"
source "${pathname}/util.sh"
source "${pathname}/pagination.sh"

parseArgs() {
  while [[ ${#*} -gt 0 ]]; do
    case ${1} in
    -h | --help)
      _showHelp "${helpTxt}" && exit 0
      ;;
    *)
      shift
      ;;
    esac
  done
}

parseArgs "${@}"

getQuery () {
  [[ ${#*} -gt 0 ]] &&
    Q="${@}" ||
    while [[ ${#Q} -eq 0 ]]; do
      read -p "search: " Q
    done
    echo "${Q}"
}

runSearch() {
  # --json fullName,description,url,stargazersCount,createdAt,updatedAt,...
  gh search repos \
    --sort "stars" \
    --limit 100 \
    --json "fullName" \
    --jq '.[].fullName' \
    "${@}"
}

_mainLoop () {
  tempfile=$(mktemp)
  q=$(getQuery "${@}")

  [[ ${#q} -gt 0 ]] &&
    declare -a searchResults="($(runSearch ${q}))"

  if [[ ${#searchResults[@]} -eq 0 ]]; then
    echo "no results"
    _mainLoop
  fi

  while true; do
    selection=""

    _paginateArray "${searchResults[@]}" -o "${tempfile}" &&
      selection=$(cat "${tempfile}")

    if [[ "${#selection}" -gt 0 ]]; then
      gh repo view "${selection}" | glow # view README.md
      _previewFiles "${selection}"       # view individual files
    else
      _mainLoop
    fi
  done
}

_mainLoop "${@}"

