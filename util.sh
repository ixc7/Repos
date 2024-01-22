#!/usr/bin/env bash

_showHelp() {
  indent=false
  helpText="
    usage: $(basename "${0}") -h [QUERY...] 

    options:
        -h, --help        show help
  "

  # unindenting the message below,
  # so i don't have to format it above
  while IFS="" read -r line; do
    # ignore blank lines
    charsOnly="${line/ //}"

    if [[ ${#charsOnly} -eq 0 ]]; then
      echo
    else
      # set indent to first non empty line
      if [[ ${indent} == false ]]; then
        indent=$(
          # get number of leading spaces
          echo "${line}" | awk -F'[^ ]' '{print length($1)}'
        )
      fi
      # formatted
      echo "${line}" | cut -c "$((indent + 1))-"
    fi
  done < <(echo "${helpText}") | bat -pp -l help
}

_parseArgs() {
  while [[ ${#*} -gt 0 ]]; do
    case ${1} in
    -h | --help)
      _showHelp
      exit 0
      ;;
    *)
      shift
      ;;
    esac
  done
}

_getInput() {
  q="${*}"

  while [[ ${#q} -eq 0 ]]; do
    read -erp "search: " q
  done

  echo "${q}"
}

_searchRepos() {
  gh search repos \
    --sort "stars" \
    --limit 100 \
    --json "fullName" \
    --jq '.[].fullName' \
    "${@}"
}

_viewReadme() {
  gh repo view "${@}" | glow -p
}
