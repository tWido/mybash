#!/bin/bash

set -euo pipefail

RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'


UTILS="bash-completion vim curl bat file ripgrep mc ranger zoxide fzf trash-cli unp fd-find jq unzip build-essential \
	gcc cmake git golang btop distrobox podman mycli python3"
UTILS_UV="isd-tui"
RUST="net" # options: deb, net, none
WIRESHARK=1
LAZYDOCKER=1
LAZYGIT=1
YAZI=1
YAZI_DEPS="ffmpegthumbnailer 7zip jq poppler-utils fd-find ripgrep fzf zoxide imagemagick xclip wl-clipboard"

SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)


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

    echo -e "${GREEN}Nerd font installed${RC}"
}

install_packages () {
    echo "Install required packages: ${UTILS}"
    sudo apt-get install -y ${UTILS}

    if [[ ${WIRESHARK} -eq 1 ]]; then
        echo "Install Wireshark"
        sudo apt-get install -y wireshark
    fi

    echo -e "${GREEN}All packages succesfully installed${RC}"
}

install_rust () {
    if is_installed rustc; then
        return
    fi

    case "${RUST}" in
            deb)
                echo "Installing Rust"
                sudo apt-get -y install cargo rustc
                echo -e "${GREEN}Rust succesfully installed${RC}"
                ;;
            net)
                echo "Installing Rust from official page"
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
                echo -e "${GREEN}Rust succesfully installed${RC}"
                ;;
            none)
                ;;
            *)
                echo -e "${RED}Unknown source for Rust installation${RC}"
                ;;
    esac
    
    source "${HOME}/.cargo/env"
}

install_starship () {
    if is_installed starship; then
        return
    fi

    echo "Installing starship"
    cargo install --locked starship
    echo -e "${GREEN}starhip succesfully installed${RC}"
}

install_yazi () {
    if is_installed yazi; then
        return
    fi

    echo "Installing yazi"

    if ! is_installed cargo; then
        echo -e "${RED}cargo required for yazi installation${RC}"
        return
    fi

    echo "Installing dependencies"
    sudo apt-get install ${YAZI_DEPS}
    cargo install --locked yazi-fm yazi-cli

    echo -e "${GREEN}yazi succesfully installed${RC}"
}

install_uv_tools () {
    echo "Installing uv"
    if cargo; then
        cargo install --git https://github.com/astral-sh/uv uv
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi

    for tool in ${UTILS_UV}; do
        echo "Install ${tool}"
        uv tool install ${tool}
    done

    echo -e "${GREEN}uv and python based tools succesfully installed${RC}"
}

install_from_github () {
    echo "Installing tools from Github"
    local prev=$(pwd)
    cd /tmp

    if [[ ${LAZYGIT} -eq 1 ]]; then
        echo "Installing lazygit"
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit -D -t /usr/local/bin/
    fi

    if [[ ${LAZYDOCKER} -eq 1 ]]; then
        echo "Installing lazydocker"
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        echo "Enable lazydocker with podman"
        systemctl --user enable --now podman.socket

        echo "## Enable podman with lazydocker" >> "${SCRIPT_PATH}/mybashrc"
        echo "export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock" >> "${SCRIPT_PATH}/mybashrc"
        echo "alias docker='podman'" >> "${SCRIPT_PATH}/mybashrc"
    fi

    echo -e "${GREEN}Tools from Github succesfully installed${RC}"
    cd "${prev}"
}

add_mybashrc () {
    local src=$(dirname $(realpath $0))
    cp "${src}/mybashrc" "${HOME}/.mybashrc"

    if ! grep mybashrc "${HOME}/.bashrc"; then
        echo "source \"${HOME}/.mybashrc\"" >> "${HOME}/.bashrc"
    fi

    cp "${src}/starship.toml" "${HOME}/.config"
}

install_packages
install_nerdfont
install_rust
install_starship
install_yazi
install_uv_tools
install_from_github
add_mybashrc

exit 0
