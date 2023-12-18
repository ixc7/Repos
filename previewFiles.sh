#!/usr/local/bin/bash

# https://docs.github.com/en/rest/repos/contents
# https://docs.github.com/en/rest/git/trees

source "$(dirname ${0})/scrollableList.sh"

_previewFiles() {
  [[ ${#*} -eq 0 ]] && exit 1

  repoName="${@}"
  branchName=$(gh api "repos/${repoName}" | jq -r '.default_branch') # "main"
  treeJSON=$(gh api "repos/${repoName}/git/trees/${branchName}?recursive=true")

  declare -a pathNames="($(echo "${treeJSON}" | jq '.tree[] | if .type == "blob" then .path else empty end'))"
  declare -a urlNames="($(echo "${treeJSON}" | jq '.tree[] | if .type == "blob" then .url else empty end'))"

  tempfile=$(mktemp)

  while true; do
    selection=""

    _scrollableList "${pathNames[@]}" -o "${tempfile}" &&
      selection=$(cat "${tempfile}")

    [[ "${#selection}" -eq 0 ]] && break

    for i in "${!pathNames[@]}"; do
      if [[ "${pathNames[i]}" == "${selection}" ]]; then
        apiURL=$(echo "${urlNames[i]}" | sed 's/.*github.com\/*//')
        gh api "${apiURL}" | jq -r '.content' | base64 -d | bat -p -l "${pathNames[i]##*.}"
      fi
    done

  done
}
