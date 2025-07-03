#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/jonas/tig"
TOOL_NAME="tig"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

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
	echo curl "${curl_opts[@]}" -o "$filename" -C - "$url"
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

		make
		make prefix="$install_path" install
	) || fail "Failed to build and install $TOOL_NAME"

	local binary_path="$install_path/bin"
	test -x "$binary_path/$TOOL_NAME" || fail "Expected $binary_path/$TOOL_NAME to be executable."
	echo "* $TOOL_NAME $version installation was successful!"
}
