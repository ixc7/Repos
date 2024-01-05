#!/usr/bin/env bash

selfdir="$(dirname "${0}")"

source "${selfdir}/ui.sh"
source "${selfdir}/util.sh"

_mainLoop() {
  outfile=$(mktemp) # used to communicate between functions
  q=$(_getInput "${@}")

  [[ ${#q} -gt 0 ]] &&
    declare -a searchResults="($(_searchRepos "${q}"))"

  [[ ${#searchResults[@]} -eq 0 ]] &&
    echo "no results" &&
    _mainLoop

  while true; do
    _viewMultiplePages "${searchResults[@]}" -o "${outfile}" &&
      selection=$(cat "${outfile}")

    if [[ "${#selection}" -gt 0 ]]; then
      branchName=$(gh api "repos/${selection}" | jq -r '.default_branch')
      treeJSON=$(gh api "repos/${selection}/git/trees/${branchName}")

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
