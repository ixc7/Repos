#!/usr/bin/env bash

_viewSinglePage() {
  outfile=""
  max=0
  pos=0
  declare -a items=()

  # utils
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

  # parse args
  while [[ ${#*} -gt 0 ]]; do
    case ${1} in
    -o | --outfile) # outfile is passed around as 'props'
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

  # empty list
  [[ ${#items[@]} -eq 0 ]] && return 1

  # limit range to screen height
  max="$((${#items[@]} - 1))"
  heightLimit=$(($(tput lines) - 1))

  [[ ${max} -gt ${heightLimit} ]] &&
    max=${heightLimit}

  # enter altbuf
  trap "tput rmcup" RETURN
  trap "tput rmcup; exit 1" SIGINT
  tput smcup

  # render list of results
  for ((i = 0; i < max; i += 1)); do
    echo -e "${items[i]}"
  done
  _mvBottom # temp fix for not printing last item in list
  _printItem
  _mvTop
  _printItemBold

  # read every keystroke
  while true; do
    read -rsn1 keypress
    case "${keypress}" in
    "A") # up
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
        echo -e "${items[pos]}" | w3m -dump >"${outfile}" # using w3m to remove color... for now.
      break
      ;;
    "q" | "Q" | "$'\e'") # quit (TODO: fix ESC key)
      return 1
      ;;
    "c") # clone repo
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
  maxHeight=$(tput lines)
  pageCount=0
  index=0
  outfile=""
  declare -a items=()
  declare -a pages=()

  # parse args
  while [[ ${#*} -gt 0 ]]; do
    case ${1} in
    -o | --outfile) # 'props' again
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

  # split input into multiple page arrays
  while true; do
    [[ ${#items[@]} -eq 0 ]] && break

    pages[pageCount]="${items[*]:0:${maxHeight}}"
    pageCount=$((pageCount + 1))
    items=(${items[@]:${maxHeight}})
  done

  # browse pages
  while true; do
    selection=""
    declare -a currentPage=(${pages[index]})

    # clear previous selection
    echo "" >${outfile}

    # render current page
    _viewSinglePage "${currentPage[@]}" -o "${outfile}" &&
      selection="$(cat "${outfile}")"

    # show next page if exists
    if [[ ${selection} == "NEXT_PAGE" ]]; then
      plusOne=$((index + 1))
      nextPage=(${pages[${plusOne}]})
      [[ ${#nextPage[@]} -gt 0 ]] && index=${plusOne}

    # show prev page if exists
    elif [[ ${selection} == "PREV_PAGE" ]]; then
      minusOne=$((index - 1))
      [[ ${minusOne} -ge 0 ]] &&
        prevPage=(${pages[${minusOne}]}) &&
        [[ ${#prevPage[@]} -gt 0 ]] &&
        index=${minusOne}

    # enter, quit, clone...
    else
      break
    fi
  done
}

_viewFileTree() {
  selection=""
  outfile=$(mktemp) # NOT props
  # using two arrays for pathname and associated url,
  # because bash doesn't do nested arrays.
  urlNamesJSON=$(echo "${*}" | jq '.tree[]? | .url')
  pathNamesJSON=$(echo "${*}" | jq '.tree[]? | .path')
  declare -a urlNames="(${urlNamesJSON})"
  declare -a pathNames="(${pathNamesJSON})"

  # using `sub()` filter to replace spaces w backslashes
  declare -a coloredPathNames=($(echo "${*}" | jq -r '
    .tree[] | 
    if .type == "tree" then 
      "\\x1b[1m" + "\\x1b[38;5;81m" + .path + "\\x1b[0m" | sub(" "; "\\"; "g") 
    elif .type == "blob" then
      "\\x1b[1m" + "\\x1b[38;5;163m" + .path + "\\x1b[0m" | sub(" "; "\\"; "g")
    else 
      empty 
    end 
  '))

  # repo is empty
  [[ ${#pathNames[@]} -eq 0 ]] && return 1

  # browse files
  while true; do
    _viewMultiplePages "${coloredPathNames[@]}" -o "${outfile}" &&
      selection=$(cat "${outfile}" | tr '\\' ' ') # un escape spaces

    # quit
    [[ "${#selection}" -eq 0 ]] && break

    # match selected path to corresponding url
    for i in "${!pathNames[@]}"; do
      if [[ "${pathNames[i]}" == "${selection}" ]]; then
        fileUrl="${urlNames[i]}"
        tempBuffer="/tmp/$(echo -n "${pathNames[i]}" | tr '/' '_')"

        # fetch+decode file contents and open in editor
        gh api "${fileUrl}" |
          jq -r '.content? // .tree?' |
          base64 -d >"${tempBuffer}" 2>/dev/null &&
          tempBufferLength="$(cat ${tempBuffer})" &&
          [[ ${#tempBufferLength} -gt 0 ]] &&
          ${EDITOR} "${tempBuffer}" ||

          # not a file; view filetree in nested directory
          _viewFileTree "$(gh api ${fileUrl})"
      fi
    done
  done
}
