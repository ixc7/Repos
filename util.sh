#!/usr/local/bin/bash

_getInput() {
  # [[ "${#@}" -gt 0 ]] &&
  q="${@}" # ||
  while [[ ${#q} -eq 0 ]]; do
    read -p "search: " q
  done

  echo "${q}"
}

# --json fullName,description,url,stargazersCount,createdAt,updatedAt,...
_ghSearchRepos() {
  gh search repos \
    --sort "stars" \
    --limit 100 \
    --json "fullName" \
    --jq '.[].fullName' \
    "${@}"
}
