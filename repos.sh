#!/usr/local/bin/bash

pathname="$(dirname ${0})"

helpTxt="
  usage: $(basename ${0}) -h [QUERY...] 

  options:
      -h, --help        show help
      -c, --config      show config
"

source "${pathname}/env.sh"
source "${pathname}/scrollableList.sh"
source "${pathname}/previewFiles.sh"
source "${pathname}/util.sh"
source "${pathname}/pagination.sh"

parseArgs() {
  while [[ ${#*} -gt 0 ]]; do
    case ${1} in
    -h | --help)
      _showHelp "${helpTxt}" && exit 0
      ;;
    -c | --config)
      bat -pp "${pathname}/env.sh" && exit 0
      ;;
    *)
      shift
      ;;
    esac
  done
}

# init
parseArgs "${@}"

# get input
[[ ${#*} -gt 0 ]] &&
  q="${@}" ||
  while [[ ${#q} -eq 0 ]]; do
    read -p "search: " q
  done

runSearch() {
  gh search repos \
    --sort "stars" \
    --limit 100 \
    --json "${json}" \
    --jq '.[].fullName' \
    "${@}"
}

[[ ${#q} -gt 0 ]] &&
  declare -a searchResults="($(runSearch ${q}))"

[[ ${#searchResults[@]} -eq 0 ]] &&
  echo "no results" &&
  exit 1

tempfile=$(mktemp)

# fzfSelect() {
#   for i in "${searchResults[@]}"; do
#     echo "${i}"
#   done |
#     fzf \
#       --preview "gh repo view {} | bat -fpp -l md" \
#       --preview-window=75% \
#       --cycle
# }

# selection=$(fzfSelect)

while true; do
  selection=""
  # TODO: echo "" > "${tempfile}"
  #       AFTER "new search" feature is implemented
  _paginateArray "${searchResults[@]}" -o "${tempfile}" &&
    # _scrollableList "${searchResults[@]}" -o "${tempfile}" &&
    selection=$(cat "${tempfile}")

  [[ "${#selection}" -eq 0 ]] && break

  # (
  gh repo view "${selection}" | glow # view README.md
  _previewFiles "${selection}"       # view individual files
  # )
done
