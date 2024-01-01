#!/usr/bin/env bash

selfdir="$(dirname "${0}")"

source "${selfdir}/paginatedList.sh"
source "${selfdir}/previewFiles.sh"
source "${selfdir}/util.sh"

_mainLoop() {
  tempfile=$(mktemp)
  q=$(_getInput "${@}")

  [[ ${#q} -gt 0 ]] &&
    declare -a searchResults="($(_ghSearchRepos "${q}"))"

  [[ ${#searchResults[@]} -eq 0 ]] &&
    echo "no results" &&
    _mainLoop

  while true; do
    _paginatedList "${searchResults[@]}" -o "${tempfile}" &&
      selection=$(cat "${tempfile}")

    if [[ "${#selection}" -gt 0 ]]; then
      _ghViewReadme "${selection}" &&   # view README.md
        _previewFiles "${selection}" || # preview files in repo
        _mainLoop                       # handle empty repos
    else
      _mainLoop
    fi
  done
}

_parseArgs "${@}"
_mainLoop "${@}"
