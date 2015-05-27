""" Colors
set t_Co=256
set nocompatible

"""" Moving Around/Editing
set splitbelow
set splitright

set wrap
set whichwrap=b,s,h,l,<,>      " <BS> <Space> h l <Left> <Right> can change lines
set virtualedit=block          " Let cursor move past the last char in <C-v> mode
set scrolloff=3                " Keep 3 context lines above and below the cursor
set backspace=indent,eol,start " allow backspacing over anything
set showmatch                  " Briefly jump to a paren once it's balanced
set matchtime=2                " (for only .2 seconds).
set autochdir                  " vim's cwd follows editor
set shortmess+=I               " no message on startup


" Emacs keybidings for command mode
cnoremap <C-A>      <Home>
cnoremap <C-E>      <End>
cnoremap <C-K>      <C-U>

" j/k navigate visual lines
noremap j gj
noremap k gk
nnoremap Q <nop>


" Tap space to clear highlighting
nmap ,i :set list!<CR>

" Write with sudo
cmap w!! w !sudo tee % >/dev/null

"""" Searching and Patterns
set ignorecase              " Default to using case insensitive searches,
set smartcase               " unless uppercase letters are used in the regex.
set hlsearch                " Highlight searches by default.
set incsearch               " Incrementally search while typing a /regex
nnoremap / /\v
vnoremap / /\v

"""" Windows, Buffers
set autoread
set ttyfast
set viminfo=!,'100,\"100,:20,<50,s10,h,n~/.viminfo

"""" Text Formatting
set encoding=utf-8
set formatoptions=

"""" Messages, Info, Status
set vb t_vb=                " Disable all bells.  I hate ringing/flashing.
set confirm                 " Y-N-C prompt if closing with unsaved changes.
set showcmd                 " Show incomplete normal mode commands as I type.
set report=0                " : commands always print changed line count.
set shortmess+=a            " Use [+]/[RO]/[w] for modified/readonly/written.
set ruler                   " Show some info, even without statuslines.
set laststatus=2            " Always show statusline, even if only 1 window.
set shell=bash
set number                  " line numbers
set numberwidth=3
set statusline=%<%f\ (%{&ft})\ %-4(%m%)%=%-19(%3l,%02c%03V%)

"""" Tabs/Indent Levels
set autoindent              " Do dumb autoindentation when no filetype is set
set tabstop=8               " Real tab characters are 8 spaces wide,
set shiftwidth=4            " but an indent level is 2 spaces wide.
set softtabstop=4           " <BS> over an autoindent deletes both spaces.
set expandtab               " Use spaces, not tabs, for autoindent/tab key.
set cindent
set smartindent
set smarttab
set textwidth=79

"""" Reading/Writing
set noautowrite             " Never write a file unless I request it.
set noautowriteall          " NEVER.
set noautoread              " Don't automatically re-read changed files.
set modeline                " Allow vim options to be embedded in files;
set modelines=5             " they must be within the first or last 5 lines.
set ffs=unix,dos,mac        " Try recognizing dos, unix, and mac line endings.

"""" Backups
set backupdir=$HOME/.vim/backup,$TMPDIR
set directory=$HOME/.vim/backup,$TMPDIR
set writebackup
set backup

if has('persistent_undo')
  set undofile
  set undodir=$HOME/.vim/undo,$TMPDIR
  set undolevels=1000
endif

"""" Menus
set gdefault                " Regexes are global by default.
set nohlsearch              " Don't highlight search results.
set wildmenu                " Menu completion in command mode on <Tab>
set wildmode=longest,list,full
set wildignore+=*.pyc,.hg,.git,.svn

""" Filetypes
filetype on                 " Enable filetype detection,
filetype indent on          " use filetype-specific indenting where available,
filetype plugin on          " also allow for filetype-specific plugins,
filetype plugin indent on   " and filetype-specific indenting
syntax on                   " and turn on per-filetype syntax highlighting.

au FileType wikipedia,text,markdown,rst setlocal wrap linebreak
au BufNewFile,BufRead *.txt setlocal ft=rst
au Filetype php setlocal ts=4 sw=4 noet
au FileType python setlocal expandtab shiftwidth=4 tabstop=8
    \ textwidth=79 formatoptions+=crq softtabstop=4 smartindent
    \ cinwords=if,elif,else,for,while,try,except,finally,def,class,with
au FileType ruby setlocal expandtab shiftwidth=4 tabstop=8
    \ formatoptions+=crq softtabstop=4 smartindent
au FileType xml,xhtml,html setlocal shiftwidth=2 tabstop=2 softtabstop=2
au FileType css setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4
au FileType rst setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4
    \ formatoptions+=nqt textwidth=74
au FileType javascript setlocal expandtab shiftwidth=4 tabstop=4
    \ softtabstop=4 formatoptions+=crq textwidth=79
au BufNewFile,BufRead *.json setlocal ft=javascript
au BufRead,BufNewFile *.pp setlocal ft=puppet
au Filetype puppet setlocal ts=4 sw=4 sts=4 et tw=80 sta
au FileType go set noet ts=8 sw=8 sts=0

colorscheme ir_black
highlight clear SignColumn

if has("user_commands")
    command! -bang -nargs=? -complete=file E e<bang> <args>
    command! -bang -nargs=? -complete=file W w<bang> <args>
    command! -bang -nargs=? -complete=file Wq wq<bang> <args>
    command! -bang -nargs=? -complete=file WQ wq<bang> <args>
    command! -bang Wa wa<bang>
    command! -bang WA wa<bang>
    command! -bang Q q<bang>
    command! -bang QA qa<bang>
    command! -bang Qa qa<bang>
endif
