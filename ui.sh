#!/usr/bin/env bash

_viewSinglePage() {
  trap "tput rmcup" RETURN

  outfile=""
  max=0
  pos=0
  declare -a items=()

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

  [[ ${#items[@]} -eq 0 ]] && return 1

  # limit range to screen height
  max="$((${#items[@]} - 1))"
  maxLines=$(($(tput lines) - 1))

  [[ ${max} -gt ${maxLines} ]] &&
    max=${maxLines}

  # render list
  trap "tput rmcup; exit 1" SIGINT
  tput smcup
  for ((i = 0; i < max; i += 1)); do
    echo "${items[i]}"
  done
  _mvBottom # temp fix for not printing last item in list
  _printItem
  _mvTop
  _printItemBold

  # read every keystroke
  while true; do
    read -rsn1 keypress
    case "${keypress}" in
    "A") # up or left
      if [[ pos -gt 0 ]]; then
        _printItem
        ((pos -= 1))
        _mvUp
      else # loop to bottom
        _printItem
        _mvBottom
      fi
      _printItemBold
      ;;
    "B") # down
      if [[ pos -lt ${max} ]]; then
        _printItem
        ((pos += 1))
        _mvDown
      else # loop to top
        _printItem
        _mvTop
      fi
      _printItemBold
      ;;
    "C") # right
      echo "NEXT_PAGE" >"${outfile}"
      break
      ;;
    "D") # left
      echo "PREV_PAGE" >"${outfile}"
      break
      ;;
    "") # enter, spacebar
      [[ -f ${outfile} ]] &&
        echo "${items[pos]}" >"${outfile}"
      break
      ;;
    "q" | "Q" | "$'\e'") # q or ESC key: quit # TODO: fix
      return 1
      ;;
    "c")
      clear
      gh repo clone "${items[pos]}" &&
        echo -e "\nsaved to '$(pwd)/\x1b[1m\x1b[38;5;10m$(echo ${items[pos]} | cut -d '/' -f 2)\x1b[0m'\n"
      read -rsn1 -p "press any key to continue "
      break
      ;;
    esac
  done
}

_viewMultiplePages() {
  max=$(tput lines) # decrease by 1?
  pageCount=0
  outfile=""
  declare -a items=()
  declare -a pages=()

  while [[ ${#*} -gt 0 ]]; do
    case ${1} in
    -o | --outfile)
      shift
      outfile="${1}"
      shift
      ;;
    *)
      items+=($(echo "${1}" | tr ' ' '\\')) # escape spaces
      shift
      ;;
    esac
  done

  # split items into pages
  while true; do
    [[ ${#items[@]} -eq 0 ]] && break

    pages[pageCount]="${items[*]:0:${max}}"
    pageCount=$((pageCount + 1))
    items=(${items[@]:${max}})
  done

  index=0
  while true; do
    selection=""
    echo "" >${outfile}

    declare -a currentPage=(${pages[index]})

    _viewSinglePage "${currentPage[@]}" -o "${outfile}" &&
      selection="$(cat "${outfile}")"

    if [[ ${selection} == "NEXT_PAGE" ]]; then
      incremented=$((index + 1))
      nextPage=(${pages[${incremented}]})

      [[ ${#nextPage[@]} -gt 0 ]] &&
        index=${incremented}

    elif [[ ${selection} == "PREV_PAGE" ]]; then
      decremented=$((index - 1))

      [[ ${decremented} -ge 0 ]] &&
        prevPage=(${pages[${decremented}]}) &&
        [[ ${#prevPage[@]} -gt 0 ]] &&
        index=${decremented}

    else
      break
    fi
  done
}

_viewFileTree() {
  outfile=$(mktemp)
  urlNamesJSON=$(echo "${*}" | jq '.tree[]? | .url')
  pathNamesJSON=$(echo "${*}" | jq '.tree[]? | .path')
  declare -a urlNames="(${urlNamesJSON})"
  declare -a pathNames="(${pathNamesJSON})"

  # repo is empty
  [[ ${#pathNames[@]} -eq 0 ]] && return 1

  while true; do
    selection=""

    _viewMultiplePages "${pathNames[@]}" -o "${outfile}" &&
      selection=$(cat "${outfile}" | tr '\\' ' ') # un escape spaces

    [[ "${#selection}" -eq 0 ]] && break

    # match selected path to corresponding url
    for i in "${!pathNames[@]}"; do
      if [[ "${pathNames[i]}" == "${selection}" ]]; then
        fileUrl="${urlNames[i]}"
        tempBuffer="/tmp/$(echo -n "${pathNames[i]}" | tr '/' '_')"

        # decode file contents and open in editor
        gh api "${fileUrl}" |
          jq -r '.content? // .tree?' |
          base64 -d >"${tempBuffer}" 2>/dev/null &&
          ${EDITOR} "${tempBuffer}" ||

          # TODO: FIX
          # not a file; view filetree in nested directory
          _viewFileTree "$(gh api ${fileUrl})"
      fi
    done
  done
}
