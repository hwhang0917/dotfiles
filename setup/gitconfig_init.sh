#!/usr/bin/env bash

set -euo pipefail

logger() {
    local message="${1:-}"
    local level="${2:-INFO}"
    case "${level}" in
        INFO)
            echo -e "\e[32m[INFO]\e[0m ${message}"
            ;;
        WARN)
            echo -e "\e[33m[WARN]\e[0m ${message}"
            ;;
        ERROR)
            echo -e "\e[31m[ERROR]\e[0m ${message}"
            ;;
        *)
            echo -e "[UNKNOWN] ${message}"
            ;;
    esac
}

if [[ ! $(command -v git) ]]; then
    logger "Git is not installed. Please install Git to proceed." "ERROR"
    exit 1
fi

if [[ ! -f "${HOME}/.gitconfig" ]]; then
    logger ".gitconfig file not found in home directory. Exiting." "ERROR"
    exit 1
fi

if ! [[ $(grep '~/.gitconfig.local' "${HOME}/.gitconfig") ]]; then
    logger "appropriate include line not found in .gitconfig. \".gitconfig.local\" will not be included." "WARN"
fi

if [[ -f "${HOME}/.gitconfig.local" ]]; then
    logger ".gitconfig.local already exists in home directory." "WARN"
else
    cat > "${HOME}/.gitconfig.local" <<EOL
[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[user]
    name = <YOUR_NAME>
    email = <YOUR_EMAIL>
    signingKey = <YOUR_PATH_TO_GPG_KEY>
EOL

    logger ".gitconfig.local has been created in your home directory." "INFO"
fi
