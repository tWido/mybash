#!/bin/bash

set -euo pipefail

UTILS="bash-completion vim curl bat file ripgrep mc ranger zoxide fzf trash-cli unp fd-find jq starship unzip build-essential gcc cmake git golang"
WIRESHARK=1
RUST="net" # options: deb, net, none
YAZI=1
YAZI_DEPS="ffmpegthumbnailer 7zip jq poppler fd-find ripgrep fzf zoxide imagemagick xclip wl-clipboard"

RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'


is_installed () {
    type "${1}" > /dev/null 2>&1
}

install_nerdfont () {
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"

    echo "Installing nerd font"
    local tmp=$(mktemp -d)
    trap "rm -rf ${tmp}" EXIT

    wget -q --show-progress "${FONT_URL}" -O "${tmp}/Hack.zip"
    unzip "${tmp}/Hack.zip" -d "${tmp}"
    mkdir -p "${HOME}/.fonts/Hack"
    mv "${tmp}"/*.ttf "${HOME}/.fonts/Hack"
    fc-cache -fv

    echo "${GREEN}Nerd font installed${RC}"
}

install_packages () {
    echo "Install required packages: ${UTILS}"
    sudo apt-get -y install ${UTILS}

    if [[ ${WIRESHARK} -eq 1 ]]; then
        echo "Install Wireshark"
        sudo apt-get -y install wireshark
    fi

    echo "${GREEN}All packages succesfully installed${RC}"
}

install_rust () {
    if is_installed rustc; then
        return
    fi

    case "${RUST}" in
            deb)
                echo "Installing Rust"
                sudo apt-get -y install cargo rustc
                echo "${GREEN}Rust succesfully installed${RC}"
                ;;
            net)
                echo "Installing Rust from official page"
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
                echo "${GREEN}Rust succesfully installed${RC}"
                ;;
            none)
                ;;
            *)
                echo "${RED}Unknown source for Rust installation${RC}"
                ;;
    esac
}

install_yazi () {
    if is_installed yazi; then
        return
    fi

    echo "Installing yazi"

    if ! is_installed cargo; then
        echo "${RED}cargo required for yazi installation${RC}"
        return
    fi

    echo "Installing dependencies"
    sudo apt-get install ${YAZI_DEPS}
    cargo install --locked yazi-fm yazi-cli

    echo "${GREEN}yazi succesfully installed${RC}"
}

add_mybashrc () {
    local src=$(dirname $(realpath $0))
    cp "${src}/mybashrc" "${HOME/.mybashrc}"
    echo "source .mybashrc" >> "${HOME/.bashrc}"
}

install_packages
install_nerdfont
install_rust
install_yazi
add_mybashrc

exit 0
