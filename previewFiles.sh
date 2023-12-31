#!/usr/bin/env bash

# https://docs.github.com/en/rest/repos/contents
# https://docs.github.com/en/rest/git/trees

source "$(dirname "${0}")/paginatedList.sh"

_previewFiles() {
  repoName="${*}"
  branchName=$(gh api "repos/${repoName}" | jq -r '.default_branch')
  treeJSON=$(gh api "repos/${repoName}/git/trees/${branchName}?recursive=true") # TODO: dirs
  urlJSON=$(echo "${treeJSON}" | jq '.tree[]? | if .type == "blob" then .url else empty end' 2>/dev/null)
  pathJSON=$(echo "${treeJSON}" | jq '.tree[]? | if .type == "blob" then .path else empty end' 2>/dev/null)
  outfile=$(mktemp)

  declare -a pathNames="(${pathJSON})"
  declare -a urlNames="(${urlJSON})"

  # repo is empty
  [[ ${#pathNames[@]} -eq 0 ]] &&
    return 1

  while true; do
    selection=""

    _paginatedList "${pathNames[@]}" -o "${outfile}" &&
      selection=$(cat "${outfile}" | tr '\\' ' ') # un escape spaces

    [[ "${#selection}" -eq 0 ]] && break

    # match selected path to corresponding url
    for i in "${!pathNames[@]}"; do
      if [[ "${pathNames[i]}" == "${selection}" ]]; then
        fileUrl=$(echo "${urlNames[i]}" | sed 's/.*github.com\/*//')
        tempfile="/tmp/$(echo -n "${pathNames[i]}" | tr '/' '_')"

        # decode file contents and open in editor
        gh api "${fileUrl}" | jq -r '.content' | base64 -d >"${tempfile}" &&
          ${EDITOR} "${tempfile}"
      fi
    done
  done
}
