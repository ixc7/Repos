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

    branchName=$(gh api "repos/${selection}" | jq -r '.default_branch')
    treeJSON=$(gh api "repos/${selection}/git/trees/${branchName}")

    if [[ "${#selection}" -gt 0 ]]; then
      _viewReadme "${selection}" &&    # view README.md
        _viewFileTree "${treeJSON}" || # preview files in repo
        _mainLoop                      # handle empty repos
    else
      _mainLoop
    fi
  done
}

_parseArgs "${@}"
_mainLoop "${@}"
