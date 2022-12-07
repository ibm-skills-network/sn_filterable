#!/bin/sh -e
version() {
  if [ -n "$1" ]; then
    echo "-v $1"
  fi
}

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

echo '::group:: Installing erb-lint ... https://github.com/Shopify/erb-lint'
# grep for erb-lint version
ERBLINT_GEMFILE_VERSION=$(ruby -ne 'print $& if /^\s{4}erb_lint\s\(\K.*(?=\))/' Gemfile.lock)

# if erb-lint version found, then pass it to the gem install
# left it empty otherwise, so no version will be passed
if [ -n "$ERBLINT_GEMFILE_VERSION" ]; then
  ERBLINT_VERSION=$ERBLINT_GEMFILE_VERSION
  else
    printf "Cannot get the erb-lint's version from Gemfile.lock. The latest version will be installed."
fi
echo '::endgroup::'

gem install -N erb_lint --version "${ERBLINT_VERSION}"

echo '::group:: Installing rubocop extensions'
# Traverse over list of rubocop extensions
for extension in $INPUT_RUBOCOP_EXTENSIONS; do
  # grep for name and version
  INPUT_RUBOCOP_EXTENSION_NAME=$(echo "$extension" |awk 'BEGIN { FS = ":" } ; { print $1 }')
  INPUT_RUBOCOP_EXTENSION_VERSION=$(echo "$extension" |awk 'BEGIN { FS = ":" } ; { print $2 }')


  # if version is 'gemfile'
  if [ "${INPUT_RUBOCOP_EXTENSION_VERSION}" = "gemfile" ]; then
    # if Gemfile.lock is here
    if [ -f 'Gemfile.lock' ]; then
      # grep for rubocop extension version
      RUBOCOP_EXTENSION_GEMFILE_VERSION=$(ruby -ne "print $& if /^\s{4}$INPUT_RUBOCOP_EXTENSION_NAME\s\(\K.*(?=\))/" Gemfile.lock)


      # if rubocop extension version found, then pass it to the gem install
      # left it empty otherwise, so no version will be passed
      if [ -n "$RUBOCOP_EXTENSION_GEMFILE_VERSION" ]; then
        RUBOCOP_EXTENSION_VERSION=$RUBOCOP_EXTENSION_GEMFILE_VERSION
        else
          printf "Cannot get the rubocop extension version from Gemfile.lock. The latest version will be installed."
      fi
      else
        printf 'Gemfile.lock not found. The latest version will be installed.'
    fi
  else
    # set desired rubocop extension version
    RUBOCOP_EXTENSION_VERSION=$INPUT_RUBOCOP_EXTENSION_VERSION
  fi

  # Handle extensions with no version qualifier
  if [ -z "${RUBOCOP_EXTENSION_VERSION}" ]; then
    unset RUBOCOP_EXTENSION_VERSION_FLAG
  else
    RUBOCOP_EXTENSION_VERSION_FLAG="--version ${RUBOCOP_EXTENSION_VERSION}"
  fi

  # shellcheck disable=SC2086
  gem install -N "${INPUT_RUBOCOP_EXTENSION_NAME}" ${RUBOCOP_EXTENSION_VERSION_FLAG}
done
echo '::endgroup::'

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

if [ "${INPUT_USE_BUNDLER}" = "false" ]; then
  BUNDLE_EXEC=""
else
  BUNDLE_EXEC="bundle exec "
fi

echo '::group:: Running erb-lint with reviewdog 🐶 ...'
# shellcheck disable=SC2086
${BUNDLE_EXEC}erblint --format compact ${INPUT_FILES} \
  | reviewdog \
      -efm="%f:%l:%c: %m" \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?
echo '::endgroup::'
exit $reviewdog_rc
