syntax enable
set cursorline
set number
set hlsearch
set ignorecase
set tabstop=4
set laststatus=2
set wildmenu
set shiftwidth=4


call plug#begin('~/.vim/plugged')

Plug 'itchyny/lightline.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'mattn/vim-lsp-settings'
Plug 'wakatime/vim-wakatime'

call plug#end()
