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

_showHelp() {
  helpText="
    usage: $(basename "${0}") -h [QUERY...] 

    options:
        -h, --help        show help
  "

  # unindenting the help message below
  # ...
  # so i don't have to write it ugly above

  indent=false

  while IFS="" read -r line; do
    # ignore empty lines
    charsOnly="${line/ //}"
    if [[ ${#charsOnly} -eq 0 ]]; then
      echo
    else
      # set indent to first non empty line
      if [[ ${indent} == false ]]; then
        indent=$(
          echo "${line}" | awk -F'[^ ]' '{print length($1)}' # get number of leading spaces
        )
      fi
      # formatted
      echo "${line}" | cut -c "$((indent + 1))-"
    fi
  done < <(echo "${helpText}") | bat -pp -l help
}
