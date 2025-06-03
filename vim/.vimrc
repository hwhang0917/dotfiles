set number
set relativenumber
set autoread
set autowrite
set nobackup
set nowritebackup
set sessionoptions-=options

set undodir=~/.vim_undodir
set belloff=all

let mapleader="\<Space>"
let g:mapleader="\<Space>"

" keymap
nnoremap <silent> <C-d> <C-d>zz
nnoremap <silent> <C-u> <C-u>zz
nnoremap <silent> n nzzzv
nnoremap <silent> N Nzzzv

" Yank to system clipboard
nnoremap <silent> <leader>y "+y
vnoremap <silent> <leader>y "+y
nnoremap <silent> <leader>Y "+Y

syntax on
