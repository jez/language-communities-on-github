#!/usr/bin/env bash

# See below for usage information

# unofficial bash strict mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

DATA_DIR="./data"
REACTIONS_DIR="$DATA_DIR/reactions"
LANGUAGES_DIR="$DATA_DIR/languages"
DATABASE="./github-data.db"
ACCEPT_REACTIONS_BETA="applicaton/json,application/vnd.github.squirrel-girl-preview,*/*"
GITHUB_API="https://api.github.com"
source .env

mkdir -p "$DATA_DIR"
mkdir -p "$REACTIONS_DIR"
mkdir -p "$LANGUAGES_DIR"

# ----- Helpers -----
# Helper colors
cnone="$(echo -ne '\033[0m')"
cwhiteb="$(echo -ne '\033[1;37m')"
cred="$(echo -ne '\033[0;31m')"
cgreen="$(echo -ne '\033[0;32m')"

# Detects whether we can add colors or not
# http://stackoverflow.com/a/911213
in_white() {
  [ -t 1 ] && echo -n "$cwhiteb"
  cat -
  [ -t 1 ] && echo -n "$cnone"
}
in_red() {
  [ -t 1 ] && echo -n "$cred"
  cat -
  [ -t 1 ] && echo -n "$cnone"
}
in_green() {
  [ -t 1 ] && echo -n "$cgreen"
  cat -
  [ -t 1 ] && echo -n "$cnone"
}
# -------------------

repo_reactions_url() {
  local repo="$1"
  local page="${2:-1}"
  echo "repos/$repo/issues/comments?client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&per_page=100&page=$page"
}

rate_limit_url() {
  echo "rate_limit?client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET"
}

select_link_header() {
  grep 'Link:'
}

extract_last_page() {
  # Match the last page with a group;
  # Replace all text on that line with just the contents of the match
  sed -E 's/.*page=([0-9]+)>; rel="last".*/\1/'
}

create_reactions_table() {
  # XXX(jez): It's important that these fields are sorted!
  #   jq outputs field names in sorted order, and doesn't look at csv headers
  sqlite3 "$DATABASE" << EOF
CREATE TABLE IF NOT EXISTS reactions (
  comments DECIMAL,
  confused DECIMAL,
  heart DECIMAL,
  hooray DECIMAL,
  language TEXT,
  laugh DECIMAL,
  repo TEXT PRIMARY KEY,
  thumbsdown DECIMAL,
  thumbsup DECIMAL,
  total_count DECIMAL
);
EOF
}

fetch_reactions() {
  local language="$1"
  shift

  local language_dir="$REACTIONS_DIR/lang-$language"
  mkdir -p "$language_dir"

  mkdir -p "$REACTIONS_DIR/csv"
  mkdir -p "$REACTIONS_DIR/pages"

  for repo in "$@"; do
    # Replace / with - in repo name
    local repo_id=${repo/\//-}

    local summaryjson="$language_dir/${repo_id}.json"

    echo "Fetching reactions for '$repo' to $summaryjson ..." | in_white

    local pagesjson="$REACTIONS_DIR/pages/${repo_id}.json"
    echo "    ...tempfile: $pagesjson"

    local url
    url="$GITHUB_API/$(repo_reactions_url "$repo")"
    echo "    ...baseurl: $url"

    # Get how many pages there are total so we can paginate the results
    local last_page
    # If there's only one page, there's no 'Link:' header, but we don't want to fail
    set +e
    last_page="$(curl -s -I "$url" | select_link_header | extract_last_page)"
    set -e
    last_page="${last_page:-1}"
    echo "    ...last_page: $last_page"

    # Make this empty before we append to it
    rm -f "$pagesjson"
    # Loop over all the pages, downloading each one
    local page_url
    for ((page=1; page<=last_page; page++)); do
      page_url="$GITHUB_API/$(repo_reactions_url "$repo" "$page")"

      echo "    ...page_url: $page_url"

      # Make request to GitHub API for current page
      curl --silent --fail -H "Accept: $ACCEPT_REACTIONS_BETA" "$page_url" | \
        # Massage the raw response into just what we want
        jq --from-file reactions-github-reponse.jq | \
          # Accumulate a sum for each property
          jq --null-input --from-file sum-each.jq >> "$pagesjson"
    done

    # Complete the newline from earlier
    echo
    echo "    ...collecting pages"

    # Collect the paginated results into one big sum
    jq --null-input --slurp --from-file sum-each.jq "$pagesjson" | \
      # Tag this row with some extra information
      jq --sort-keys ". + {language: \"$language\", repo: \"$repo\"}" > "$summaryjson"

    echo "    ...done." | in_green
  done

  # Generate the CSV for this language from all the summaryjson
  local languagecsv="$REACTIONS_DIR/csv/lang-${language}.csv"
  jq --slurp --raw-output --from-file as-csv.jq \
    "$language_dir/"*.json > "$languagecsv"

  # Import the CSV into SQLite
  create_reactions_table
  sqlite3 -csv "$DATABASE" <<< ".import $languagecsv reactions"
}

#| driver.sh - Utility for getting assorted data from GitHub
#|
#| Usage:
#|   driver.sh reactions <language> <user>/<repo> ...
#|   driver.sh reactions --from-file
#|   driver.sh sql
#|   driver.sh ratelimit
#|   driver.sh clean
#|
#| <user>/<repo> should correspond to a GitHub repo.
#| --from-file   instead of specifying a language and repos,
#|               read from files in data/languages/*.txt
#| sql           initializes SQLite database tables

command=${1:-}
case "$command" in
  reactions)
    shift
    case "$1" in
      --from-file)
        shift
        for language_file in "$LANGUAGES_DIR"/*.txt; do
          __language="$(basename "$language_file" .txt)"
          # We actually want word splitting
          # shellcheck disable=SC2046
          fetch_reactions "$__language" $(xargs < "$language_file")
        done
        ;;
      *)
        fetch_reactions "$@"
        ;;
    esac
    ;;
  sql)
    create_reactions_table
    ;;
  ratelimit)
    curl --silent -I "$GITHUB_API/$(rate_limit_url)" | grep RateLimit
    ;;
  clean)
    # TODO(jez)
    echo 'TODO!'
    ;;
  *)
    grep '^#|' "$0" | cut -c 4-
    exit 1
    ;;
esac
