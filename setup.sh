#!/usr/bin/env bash

declare -a dependencies=(jq gh bat glow awk)
declare -a notInstalled=()

for i in "${dependencies[@]}"; do
  which ${i} 1>/dev/null || notInstalled+=(${i})
done

if [[ ${#notInstalled[@]} -eq 0 ]]; then
  echo "all dependencies installed!"

else
  text="${notInstalled[@]}"
  echo "installing: ${text// /, }"
  brew install ${notInstalled[@]} &&
    echo "all dependencies installed!" && exit 0 ||
    echo "warning: could not install all dependencies" && exit 1
fi
