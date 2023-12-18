#!/usr/local/bin/bash

_scrollableList() {
  declare -a items=()
  outfile=""
  max=0
  pos=0

  mvUp() { echo -ne "\x1b[1A\r"; }
  mvDown() { echo -ne "\x1b[1B\r"; }
  mvTop() {
    pos=0
    tput cup 0 0
  }
  mvBottom() {
    pos=${max}
    tput cup ${max} 0
  }
  printItem() { echo -ne "${items[pos]}\r"; }
  printItemBold() { echo -ne "\x1b[1m${items[pos]}\x1b[0m\r"; }

  trapSIGINT() {
    tput rmcup
    exit 1
  }

  parseArgs() {
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

  # init
  parseArgs "${@}"

  [[ ${#items[@]} -eq 0 ]] &&
    exit 1

  trap trapSIGINT SIGINT
  tput smcup

  max="$((${#items[@]} - 1))"
  maxLines=$(($(tput lines) - 1))

  # limit range to screen height
  if [[ ${max} -gt ${maxLines} ]]; then
    max=${maxLines}
  fi

  # render list
  for ((i = 0; i < ${max}; i += 1)); do
    echo "${items[i]}"
    # skipping last item on first render, needs `echo -n`
  done

  mvTop
  printItemBold

  # read every keystroke
  while true; do
    read -rsn1 keypress

    case "${keypress}" in
    # up
    "A")
      if [[ pos -gt 0 ]]; then
        printItem
        ((pos -= 1))
        mvUp
      else
        # loop back to bottom
        printItem
        mvBottom
      fi
      printItemBold
      ;;

    # down
    "B")
      if [[ pos -lt ${max} ]]; then
        printItem
        ((pos += 1))
        mvDown
      else
        # loop back to top
        printItem
        mvTop
      fi
      printItemBold
      ;;

    # enter
    "")
      tput rmcup
      if [[ ${#outfile} -eq 0 ]]; then
        printItem
        echo
      else
        echo "${items[pos]}" >"${outfile}"
      fi
      break
      ;;

    # quit
    "q" | "Q")
      tput rmcup
      exit 1
      ;;
    esac
  done
}
