#!/usr/local/bin/bash

_scrollableList() {
  declare -a items=()
  outfile=""
  max=0
  pos=0

  _mvUp() { echo -ne "\x1b[1A\r"; }

  _mvDown() { echo -ne "\x1b[1B\r"; }

  _mvTop() {
    pos=0
    tput cup 0 0
  }

  _mvBottom() {
    pos=${max}
    tput cup ${max} 0
  }

  _printItem() { echo -ne "${items[pos]}\r"; }

  _printItemBold() { echo -ne "\x1b[1m${items[pos]}\x1b[0m\r"; }

  _trapSIGINT() {
    tput rmcup
    exit 1
  }

  _parseArgs() {
    while [[ ${#*} -gt 0 ]]; do
      case ${1} in
      -o | --outfile)
        shift
        outfile="${1}"
        shift
        ;;
      *)
        items+=("${1}")
        shift
        ;;
      esac
    done
  }

  _parseArgs "${@}"

  [[ ${#items[@]} -eq 0 ]] &&
    return 1

  trap _trapSIGINT SIGINT
  tput smcup

  max="$((${#items[@]} - 1))"
  maxLines=$(($(tput lines) - 1))

  # limit range to screen height
  [[ ${max} -gt ${maxLines} ]] &&
    max=${maxLines}

  # render list
  for ((i = 0; i < ${max}; i += 1)); do
    echo "${items[i]}"
    # skipping last item on first render, needs `echo -n`
  done

  _mvTop
  _printItemBold

  # read every keystroke
  while true; do
    read -rsn1 keypress

    case "${keypress}" in
    # up
    "A")
      if [[ pos -gt 0 ]]; then
        _printItem
        ((pos -= 1))
        _mvUp
      else
        # loop to bottom
        _printItem
        _mvBottom
      fi
      _printItemBold
      ;;

    # down
    "B")
      if [[ pos -lt ${max} ]]; then
        _printItem
        ((pos += 1))
        _mvDown
      else
        # loop to top
        _printItem
        _mvTop
      fi
      _printItemBold
      ;;

    # enter
    "")
      tput rmcup
      if [[ ${#outfile} -eq 0 ]]; then
        _printItem
        echo
      else
        echo "${items[pos]}" >"${outfile}"
      fi
      break
      ;;

    # quit
    "q" | "Q")
      tput rmcup
      return 1
      ;;
    esac
  done
}
