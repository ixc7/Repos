#!/usr/bin/env bash

_getInput() {
  q="${*}"

  while [[ ${#q} -eq 0 ]]; do
    read -erp "search: " q
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

_ghViewReadme() {
  gh repo view "${@}" | glow -p
}
