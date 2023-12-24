#!/usr/local/bin/bash

pathname="$(dirname ${0})"

source "${pathname}/help.sh"
source "${pathname}/util.sh"
source "${pathname}/previewFiles.sh"
source "${pathname}/pagination.sh"

_parseHelpArgs "${@}"

_mainLoop() {
  tempfile=$(mktemp)
  q=$(_getInput "${@}")

  [[ ${#q} -gt 0 ]] &&
    declare -a searchResults="($(_ghSearchRepos ${q}))"

  [[ ${#searchResults[@]} -eq 0 ]] &&
    echo "no results" &&
    _mainLoop

  while true; do
    _paginateArray "${searchResults[@]}" -o "${tempfile}" &&
      selection=$(cat "${tempfile}")

    if [[ "${#selection}" -gt 0 ]]; then
      gh repo view "${selection}" | glow # view README.md
      _previewFiles "${selection}" ||    # preview files in repo
        _mainLoop                        # handle empty repos
    else
      _mainLoop
    fi
  done
}

_mainLoop "${@}"
