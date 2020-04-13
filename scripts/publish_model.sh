#!/bin/bash

# Building packages and uploading them to a Gemfury repo.

export $(grep -E -v '^#' .env | xargs)
GEMFURY_URL=https://${FURY_PUSH}:@push.fury.io/${FURY_USERNAME}/

set -e

DIRS="$@"
BASE_DIR=$(pwd)
SETUP="setup.py"

warn() {
    echo "Error:"
    echo "$@" 1>&2
}

die() {
    warn "$@"
    exit 1
}

build() {
    DIR="${1/%\//}"
    echo "Checking directory $DIR"
    cd "$BASE_DIR/$DIR"
    [ ! -e $SETUP ] && warn "No $SETUP file, skipping" && return

    PACKAGE_NAME=$(python $SETUP --fullname)
    echo "Building package $PACKAGE_NAME"
    python "$SETUP" sdist bdist_wheel || die "Building package" $PACKAGE
    echo "Finished building package $PACKAGE_NAME"

    for X in $(ls dist)
    do
        curl -F package=@"dist/$X" ${GEMFURY_URL} || die "Uploading file $X from $PACKAGE_NAME"
    done
}

if [ -n "$DIRS" ]; then
    for dir in $DIRS; do
        build $dir
    done
else
    ls -d */ | while read dir; do
        build $dir
    done
fi

