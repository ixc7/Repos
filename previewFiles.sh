#!/usr/local/bin/bash

# https://docs.github.com/en/rest/repos/contents
# https://docs.github.com/en/rest/git/trees

repoName="ixc7/repos"
branchName=$(gh api "repos/${repoName}" | jq -r '.default_branch') # "main"
treeJSON=$(gh api "repos/${repoName}/git/trees/${branchName}?recursive=true")

declare -a pathNames="($(echo "${treeJSON}" | jq '.tree[] | if .type == "blob" then .path else empty end'))"
declare -a urlNames="($(echo "${treeJSON}" | jq '.tree[] | if .type == "blob" then .url else empty end'))"

ns
echo "found ${#pathNames[@]} files in ${repoName} (${branchName})"

for i in "${!pathNames[@]}"; do
  echo "
    filename: ${pathNames[i]}
    url: ${urlNames[i]}
  "
  apiURL=$(echo "${urlNames[i]}" | sed 's/.*github.com\/*//')
  gh api "${apiURL}" | jq -r '.content' | base64 -d | bat -pp -l "${pathNames[i]##*.}"
  read
done

# echo "${treeJSON}" |
# jq -r '.tree[] | .url' |
# sed 's/.*github.com\/*//' |
# xargs -n 1 gh api |
# jq -r '.content' | base64 -d |
