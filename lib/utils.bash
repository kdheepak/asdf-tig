#!/usr/bin/env bash

set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for tig.
GH_REPO="https://github.com/jonas/tig"
TOOL_NAME="tig"
TOOL_TEST="tig --help"

fail() {
    echo -e "asdf-$TOOL_NAME: $*"
    exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if tig is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
    curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
    sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
        LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
    git ls-remote --tags --refs "$GH_REPO" |
        grep -o 'refs/tags/.*' | cut -d/ -f3- |
        sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
    list_github_tags
}

download_release() {
    local version filename url
    version="$1"
    filename="$2"

    url="$GH_REPO/archive/${version}.tar.gz"

    echo "* Downloading $TOOL_NAME release $version..."
    curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
    local install_type="$1"
    local version="$2"
    local install_path="$3"

    if [ "$install_type" != "version" ]; then
        fail "asdf-$TOOL_NAME supports release installs only"
    fi

    echo "* Building $TOOL_NAME $version from source..."

    (
        cd "$ASDF_DOWNLOAD_PATH"

        ./autogen.sh || true # sometimes needed
        ./configure --prefix="$install_path"
        make
        make install prefix="$install_path"
    ) || fail "Failed to build and install $TOOL_NAME"

    echo "$TOOL_NAME $version installation was successful!"
}
