#!/usr/bin/env bash

# https://docs.github.com/en/rest/repos/contents
# https://docs.github.com/en/rest/git/trees

source "$(dirname "${0}")/paginatedList.sh"

_previewFiles() {
  [[ ${#*} -eq 0 ]] && return 1

  tempfile=$(mktemp)

  repoName="${*}"
  branchName=$(gh api "repos/${repoName}" | jq -r '.default_branch')
  treeJSON=$(gh api "repos/${repoName}/git/trees/${branchName}?recursive=true")
  URLsJSON=$(echo "${treeJSON}" | jq '.tree[]? | if .type == "blob" then .url else empty end' 2>/dev/null)
  pathsJSON=$(echo "${treeJSON}" | jq '.tree[]? | if .type == "blob" then .path else empty end' 2>/dev/null)

  declare -a pathNames="(${pathsJSON})"
  declare -a urlNames="(${URLsJSON})"

  # repo is empty
  [[ ${#pathNames[@]} -eq 0 ]] &&
    return 1

  while true; do
    selection=""

    _paginatedList "${pathNames[@]}" -o "${tempfile}" &&
      selection=$(cat "${tempfile}")

    [[ "${#selection}" -eq 0 ]] && break

    echo "got $selection"
    # match selected path to corresponding url
    for i in "${!pathNames[@]}"; do
      if [[ "${pathNames[i]}" == "${selection}" ]]; then
        apiURL=$(echo "${urlNames[i]}" | sed 's/.*github.com\/*//')
        filename="/tmp/$(echo -n "${pathNames[i]}" | tr '/' '_')"

        # decode file contents and open in editor
        gh api "${apiURL}" | jq -r '.content' | base64 -d >"${filename}" &&
          ${EDITOR} "${filename}"
      fi
    done
  done
}
