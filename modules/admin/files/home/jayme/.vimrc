" Specify a directory for plugins
" managed by https://github.com/junegunn/vim-plug
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
" Make sure you use single quotes
Plug 'https://github.com/preservim/nerdtree'
Plug 'https://github.com/altercation/vim-colors-solarized'

Plug 'https://github.com/rodjek/vim-puppet'
Plug 'https://github.com/google/vim-jsonnet'
Plug 'https://github.com/towolf/vim-helm'

" Initialize plugin system
call plug#end()

colorscheme solarized
set background  =light
set t_Co        =256 "Fix detection of 256-color screen in tmux
set mouse       =""
set autoindent
set tabstop     =4 "Width of tab character
set softtabstop =4 "Fine tunes the amount of white space to be adde
set shiftwidth  =4 "Determines the amount of whitespace to add in normal mode
set expandtab      "use spaces instead of tabs
set ignorecase
set smartcase
set incsearch
set hlsearch
highlight BadWhitespace ctermbg=red guibg=red
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" NERDTree
let NERDTreeShowHidden  = 1
let NERDTreeHijackNetrw = 1
let NERDTreeIgnore      = ['\.pyc$', '\~$'] "ignore files in NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
map <C-n> :NERDTreeToggle<CR>
command E NERDTreeToggle

" vim-jsonnet
let g:jsonnet_fmt_options="-n 2"
autocmd FileType jsonnet setlocal ts=2 sts=2 sw=2 expandtab

" vim-helm
autocmd BufRead,BufNewFile */deployment-charts/*.yaml,*/deployment-charts/*.tpl set ft=helm
autocmd FileType helm setlocal ts=2 sts=2 sw=2 expandtab
