#!/usr/local/bin/bash

# https://docs.github.com/en/rest/repos/contents
# https://docs.github.com/en/rest/git/trees

source "$(dirname ${0})/scrollableList.sh"

repoName="ixc7/repos"
branchName=$(gh api "repos/${repoName}" | jq -r '.default_branch') # "main"
treeJSON=$(gh api "repos/${repoName}/git/trees/${branchName}?recursive=true")

declare -a pathNames="($(echo "${treeJSON}" | jq '.tree[] | if .type == "blob" then .path else empty end'))"
declare -a urlNames="($(echo "${treeJSON}" | jq '.tree[] | if .type == "blob" then .url else empty end'))"

# ns
# echo "found ${#pathNames[@]} files in ${repoName} (${branchName})"

# for i in "${!pathNames[@]}"; do
#   echo "
#     filename: ${pathNames[i]}
#     url: ${urlNames[i]}
#   "
#   apiURL=$(echo "${urlNames[i]}" | sed 's/.*github.com\/*//')
#   gh api "${apiURL}" | jq -r '.content' | base64 -d | bat -pp -l "${pathNames[i]##*.}"
#   read
# done

tempfile=$(mktemp)

while true; do
  selection=""
  apiURL=""

  _scrollableList "${pathNames[@]}" -o "${tempfile}" &&
    selection=$(cat "${tempfile}")

  [[ "${#selection}" -eq 0 ]] && break
  
  for i in "${!pathNames[@]}"; do
    if [[ "${pathNames[i]}" == "${selection}" ]]; then
      apiURL=$(echo "${urlNames[i]}" | sed 's/.*github.com\/*//')
      gh api "${apiURL}" | jq -r '.content' | base64 -d | bat -p # -l "${pathNames[i]##*.}"
      break
    fi
  done
  
done

