set nocompatible               " be iMproved
filetype off                   " required!

filetype plugin indent on     " required!

syntax on
set hidden              " Allow more than one buffer open at a time
set autoindent      " Copy current indent level to newline
set smartindent     " Smart indent / oudent based on context (extra indent level after a if (...) { for example
set incsearch       " Search as you type
set nohlsearch      " Do not highlight all search results
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab       " Fuck hard tabs
set autoread
set history=1000
set synmaxcol=400
set ignorecase
set smartcase
set title
set gdefault
set relativenumber  " Number lines relatively based on diff from current location.
set cursorline      " Highlight line cursor is currently on
set laststatus=2
set wildmenu
set wildmode=list:longest
set showmatch       " Automatically highlight matching braces
" Use the system keyboard for everything!
set clipboard+=unnamedplus


" When you open a file as normal user but need to sudo to write to it
cmap w!! w !sudo tee % >/dev/null

let mapleader=","   " Much easier to hit than /

"fix regex searching
nnoremap / /\v
vnoremap / /\v

" Much easier to hit than shift+;
nnoremap ; :

"visual line movements - makes working with wrapped lines easier
:map j gj
:map k gk
:map ' `

"autosave on lost focus
:au FocusLost * silent! wa
