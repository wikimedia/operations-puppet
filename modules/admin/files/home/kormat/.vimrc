set nocompatible

" ======================
" Terminal setup
" ======================

" https://superuser.com/a/402084
if &term =~ "^screen"
    " tmux will send xterm-style keys when its xterm-keys option is on
    exe "set <xUp>=\e[1;*A"
    exe "set <xDown>=\e[1;*B"
    exe "set <xRight>=\e[1;*C"
    exe "set <xLeft>=\e[1;*D"
endif

if filereadable(expand("~/.vim/autoload/plug.vim"))
    source ~/.vim/plug.vim
endif

" ======================
" Settings
" ======================

" Statefulness
set undodir=~/.vim/undo   " persistent undo storage
set undofile              " persistent undo on
set history=1000          " remember command mode history

" user interface
set showcmd               " Show (partial) command in status line.
set matchtime=2           " How many 1/10s to show matching brackets for.
set scrolloff=2           " always have 2 lines of context on the screen
set display=uhex          " show unprintable characters as <xx>

" Whitespace
set shiftwidth=4          " one tab = four spaces (autoindent)
set softtabstop=4         " one tab = four spaces (tab key)
set expandtab             " never use hard tabs
set shiftround            " only indent to multiples of shiftwidth
set linebreak             " break on what looks like boundaries
set listchars=tab:↹·,extends:⇉,precedes:⇇,nbsp:␠,trail:␠,nbsp:␣
                          " appearance of invisible characters

" Mouse
set ttymouse=xterm2       " force mouse support for screen
"set mouse=a               " terminal mouse when possible

" File formats
set fileformats=unix,dos  " unix linebreaks in new files please
set encoding=utf-8        " best default encoding
setglobal fileencoding=utf-8
set nobomb                " do not write utf-8 BOM!
set fileencodings=ucs-bom,utf-8,iso-8859-1
                          " order to detect Unicodeyness

" tab completion for filenames
set wildmode=longest,list,full
set wildignore+=.*.sw*,__pycache__,*.pyc " ignore junk files

"Misc options
set pastetoggle=<F11>     " Toggle paste on and off with F11
set splitbelow            " Open new horizontal windows below
set splitright            " Open new vertical windows on the right

" Set spell-checking dictionary
set spelllang=en_gb

" ======================
" Mappings
" ======================

" Leader
let mapleader = "\\"
let g:mapleader = "\\"

" https://stackoverflow.com/a/10216459
let c='a'
while c <= 'z'
    exec "set <A-".c.">=\e".c
    exec "imap \e".c." <A-".c.">"
    let c = nr2char(1+char2nr(c))
endw
let c='0'
while c <= '9'
    exec "set <A-".c.">=\e".c
    exec "imap \e".c." <A-".c.">"
    let c = nr2char(1+char2nr(c))
endw
set ttimeout ttimeoutlen=50

" alt-asdf to switch windows
nnoremap <A-a> <C-W><Left>
nnoremap <A-d> <C-W><Right>
nnoremap <A-w> <C-W><Up>
nnoremap <A-s> <C-W><Down>
inoremap <A-a> <C-O><C-W><Left>
inoremap <A-d> <C-O><C-W><Right>
inoremap <A-w> <C-O><C-W><Up>
inoremap <A-s> <C-O><C-W><Down>
" alt-1 and alt-2 to switch tabs
nnoremap <A-2> gt
nnoremap <A-1> gT
inoremap <A-2> <C-O>gt
inoremap <A-1> <C-O>gT

" Abbreviation to make `:e %%/...` edit in same directory
cabbr <expr> %% expand('%:.:h')

" Toggle on/off spell checking
map <Leader>sp :set spell!<cr>
" Toggle on/off line numbers
map <Leader>ln :call ToggleLineNumbers()<cr>

" ======================
" Misc scripts
" ======================

" Always set 'wrap' on for vimdiff, and jump to top
autocmd VimEnter * if &diff | call DiffCheck() | endif
function DiffCheck()
  exe 'normal gg'
  exe 'windo set wrap'
endfunction

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis

function! ToggleLineNumbers()
    if &number
        set nonumber
    else
        set number
    endif
endfunction

" ======================
" Color & syntax
" ======================
if &t_Co > 2 || has("gui_running")
  set background=dark
endif

" When editing a file, always jump to the last known cursor position.
autocmd BufReadPost *
      \ if line("'\"") > 0 && line("'\"") <= line("$") |
      \   exe "normal g`\"" |
      \ endif

" trailing whitespace; must define AFTER colorscheme, setf, etc!
hi WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+\%#\@<!$/

autocmd FileType yaml setlocal shiftwidth=2 tabstop=2

" ======================
" Source local config if present
" ======================
let localrc=expand("~/.vim/local.vim")
if filereadable(localrc)
  exe "source " . localrc
endif
