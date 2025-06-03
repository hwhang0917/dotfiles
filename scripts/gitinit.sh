#!/usr/bin/env sh

cat << EOF > "$HOME/.gitconfig.local"
; I use gh-cli to manage my git credentials
[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[user]
    ; signingkey = <path to your signing key>
    ; email = <your email>
    ; name = <your name>
EOF
