#!/bin/sh

while read -r key value; do
    tag=${value##*/}
    tag=${tag%%\"*}
    printf %s\\n "$tag"
done <<EOF
$(curl -s https://api.github.com/repos/NixOS/nixpkgs/git/matching-refs/tags | \
  grep -E -e '"ref": "refs/tags/[0-9]{2}.[0-9]{2}(-beta)?",')
EOF
