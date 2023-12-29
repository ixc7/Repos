#!/usr/local/bin/bash

helpTxt="
  usage: $(basename "${0}") -h [QUERY...] 

  options:
      -h, --help        show help
"

_unindent() {
  [[ ${#*} -eq 0 ]] && return 1

  local msg="${*}"
  local indent=false

  _printLine() {
    while IFS= read -r line; do
      # line with spaces removed
      noSpaces="${line/ //}"

      # skip empty lines
      if [[ ${#noSpaces} -eq 0 ]]; then
        echo
      else
        # set `indent` if not set
        if [[ ${indent} == false ]]; then
          indent=$(
            # set `indent` to first non-empty line found
            echo "${line}" |
              # get number of leading spaces before first word
              awk -F'[^ ]' '{print length($1)}'
          )
        fi
        # print formatted line
        echo "${line}" | cut -c "$((indent + 1))-${#line}"
      fi
    done < <(echo "${msg}") # pass text to IFS loop
  }

  # echo "$(
  _printLine
  # )"
}

_showHelp() {
  _unindent "${@}" |
    tail -n +2 |
    bat -pp -l help &&
    echo
}

_parseHelpArgs() {
  while [[ ${#*} -gt 0 ]]; do
    case ${1} in
    -h | --help)
      _showHelp "${helpTxt}" && exit 0
      ;;
    *)
      shift
      ;;
    esac
  done
}
