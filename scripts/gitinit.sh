#!/usr/bin/env bash

cat << EOF > "$HOME/.gitconfig.local"
; I use ghcli to manage my git credentials
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
