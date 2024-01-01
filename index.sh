#!/usr/bin/env bash

selfdir="$(dirname "${0}")"

source "${selfdir}/ui.sh"
source "${selfdir}/util.sh"

_mainLoop() {
  outfile=$(mktemp)
  q=$(_getInput "${@}")

  [[ ${#q} -gt 0 ]] &&
    declare -a searchResults="($(_searchRepos "${q}"))"

  [[ ${#searchResults[@]} -eq 0 ]] &&
    echo "no results" &&
    _mainLoop

  while true; do
    _multiplePages "${searchResults[@]}" -o "${outfile}" &&
      selection=$(cat "${outfile}")

    if [[ "${#selection}" -gt 0 ]]; then
      _viewReadme "${selection}" &&     # view README.md
        _viewFileTree "${selection}" || # preview files in repo
        _mainLoop                       # handle empty repos
    else
      _mainLoop
    fi
  done
}

_parseArgs "${@}"
_mainLoop "${@}"
