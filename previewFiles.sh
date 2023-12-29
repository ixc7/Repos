#!/usr/local/bin/bash

# https://docs.github.com/en/rest/repos/contents
# https://docs.github.com/en/rest/git/trees

source "$(dirname "${0}")/paginatedList.sh"

_previewFiles() {
  [[ ${#*} -eq 0 ]] && return 1

  repoName="${*}"
  tempfile=$(mktemp)

  branchName=$(gh api "repos/${repoName}" | jq -r '.default_branch')
  treeJSON=$(gh api "repos/${repoName}/git/trees/${branchName}?recursive=true")

  declare -a pathNames="($(
    echo "${treeJSON}" |
      jq '.tree[]? | if .type == "blob" then .path else empty end' 2>/dev/null
  ))"

  declare -a urlNames="($(
    echo "${treeJSON}" |
      jq '.tree[]? | if .type == "blob" then .url else empty end' 2>/dev/null
  ))"

  # repo is empty
  [[ ${#pathNames[@]} -eq 0 ]] &&
    return 1

  while true; do
    selection=""

    _paginatedList "${pathNames[@]}" -o "${tempfile}" &&
      selection=$(cat "${tempfile}")

    [[ "${#selection}" -eq 0 ]] && break

    # match selected path to corresponding url
    for i in "${!pathNames[@]}"; do
      if [[ "${pathNames[i]}" == "${selection}" ]]; then
        apiURL=$(echo "${urlNames[i]}" | sed 's/.*github.com\/*//')
        filename="/tmp/$(echo -n "${pathNames[i]}" | tr '/' '_')"

        # decode file contents
        gh api "${apiURL}" | jq -r '.content' | base64 -d >"${filename}" &&
          # open in editor
          ${EDITOR} "${filename}"
      fi
    done
  done
}
