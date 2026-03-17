FROM alpine:latest

RUN apk add --no-cache neovim git gcc musl-dev unzip curl ripgrep nodejs npm

COPY . /root/.config/nvim

CMD ["nvim"]
