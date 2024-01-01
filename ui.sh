#!/usr/bin/env bash

# https://docs.github.com/en/rest/repos/contents
# https://docs.github.com/en/rest/git/trees

_singlePage() {
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

  # limit range to screen height
  max="$((${#items[@]} - 1))"
  maxLines=$(($(tput lines) - 1))

  [[ ${max} -gt ${maxLines} ]] &&
    max=${maxLines}

  # render list
  trap "tput rmcup; exit 1" SIGINT
  tput smcup
  for ((i = 0; i < max; i += 1)); do
    echo "${items[i]}" # skipping last item on first render, needs `echo -n`
  done
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
    "")
      tput rmcup # enter
      if [[ ${#outfile} -eq 0 ]]; then
        _printItem
        echo
      else
        echo "${items[pos]}" >"${outfile}"
      fi
      break
      ;;
    "q" | "Q") # quit
      tput rmcup
      return 1
      ;;
    esac
  done
}

_multiplePages() {
  declare -a items=()
  declare -a pages=()
  max=$(tput lines) # decrease by 1?
  pageCount=0
  outfile=""

  _parseArgs() {
    while [[ ${#*} -gt 0 ]]; do
      case ${1} in
      -o | --outfile)
        shift
        outfile="${1}"
        shift
        ;;
      *)
      items+=($( echo "${1}" | tr ' ' '\\')) # escape spaces
        shift
        ;;
      esac
    done
  }

  _parseArgs "${@}"

  while true; do
    [[ ${#items[@]} -eq 0 ]] &&
      break

      pages[pageCount]="${items[*]:0:${max}}"
      pageCount=$((pageCount + 1))
      items=(${items[@]:${max}})
  done

  for i in "${!pages[@]}"; do
    declare -a currentPage=(${pages[i]})

    _singlePage "${currentPage[@]}" -o "${outfile}" &&
      selection="$(cat "${outfile}")"
    
    [[ ${#selection} -gt 0 ]] &&
      break
  done
}

_viewFileTree() {
  outfile=$(mktemp)
  repoName="${*}"
  branchName=$(gh api "repos/${repoName}" | jq -r '.default_branch')
  treeJSON=$(gh api "repos/${repoName}/git/trees/${branchName}?recursive=true") # TODO: dirs
  urlJSON=$(echo "${treeJSON}" | jq '.tree[]? | if .type == "blob" then .url else empty end' 2>/dev/null)
  pathJSON=$(echo "${treeJSON}" | jq '.tree[]? | if .type == "blob" then .path else empty end' 2>/dev/null)
  declare -a urlNames="(${urlJSON})"
  declare -a pathNames="(${pathJSON})"

  # repo is empty
  [[ ${#pathNames[@]} -eq 0 ]] &&
    return 1

  while true; do
    selection=""
    _multiplePages "${pathNames[@]}" -o "${outfile}" &&
      selection=$(cat "${outfile}" | tr '\\' ' ') # un escape spaces

    [[ "${#selection}" -eq 0 ]] && break

    # match selected path to corresponding url
    for i in "${!pathNames[@]}"; do
      if [[ "${pathNames[i]}" == "${selection}" ]]; then
        fileUrl=$(echo "${urlNames[i]}" | sed 's/.*github.com\/*//')
        tempfile="/tmp/$(echo -n "${pathNames[i]}" | tr '/' '_')"

        # decode file contents and open in editor
        gh api "${fileUrl}" | jq -r '.content' | base64 -d >"${tempfile}" &&
          ${EDITOR} "${tempfile}"
      fi
    done
  done
}
