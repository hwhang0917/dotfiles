FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm neovim git gcc unzip curl ripgrep nodejs npm && \
    pacman -Scc --noconfirm

COPY . /root/.config/nvim

CMD ["nvim"]
