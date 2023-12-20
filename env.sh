#!/usr/local/bin/bash

# view README.md files
# pager="glow"
pager="bat -p -l md"

# max results to fetch (limit 100)
# maxHeight=$(($(tput lines) - 1))

# max text length before truncating
maxWidth=$(($(tput cols) - 4))

# JSON fields (fullName,description,url,stargazersCount,createdAt,updatedAt...)
json="fullName"

# output template (--template "${template}")
# see `gh help formatting`
# template="Results:
# {{range .}}
# {{hyperlink .url .fullName}}
# \"{{truncate (${maxWidth}) .description}}\"
#   + {{.stargazersCount}} stars
#   + created: {{(timefmt \"1/1/2006\" .createdAt)}}
#   + updated: {{(timefmt \"1/1/2006\" .updatedAt)}}
# {{end}}
# "
