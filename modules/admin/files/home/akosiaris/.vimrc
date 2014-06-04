" vim: set foldmarker={,} foldlevel=0 spell:

" Basics {
     set nocompatible " explicitly get out of vi-compatible mode
"    set noexrc " don't use local version of .(g)vimrc, .exrc
"    set background=dark " we plan to use a dark background
     set cpoptions=aABceFsmq
     "             |||||||||
     "             ||||||||+-- When joining lines, leave the cursor
     "             |||||||      between joined lines
     "             |||||||+-- When a new match is created (showmatch)
     "             ||||||      pause for .5
     "             ||||||+-- Set buffer options when entering the
     "             |||||      buffer
     "             |||||+-- :write command updates current file name
     "             ||||+-- Automatically add <CR> to the last line
     "             |||      when using :@r
     "             |||+-- Searching continues at the end of the match
     "             ||      at the cursor position
     "             ||+-- A backslash has no special meaning in mappings
     "             |+-- :write updates alternative file name
     "             +-- :read updates alternative file name
     syntax on " syntax highlighting on
" }

" General {
     filetype plugin indent on " load filetype plugins/indent settings
"    set autochdir " always switch to the current file directory
    set backspace=indent,eol,start " make backspace a more flexible
"    set backup " make backup files
"    set backupdir=~/.vim/backup " where to put backup files
"    set clipboard+=unnamed " share windows clipboard
"    set directory=~/.vim/tmp " directory to place swap files in
     set fileformats=unix,dos,mac " support all three, in this order
"    set hidden " you can change buffers without saving
    " (XXX: #VIM/tpope warns the line below could break things)
"    set iskeyword+=_,$,@,%,# " none of these are word dividers
"    set mouse=a " use mouse everywhere
     set noerrorbells " don't make noise
"    set whichwrap=b,s,h,l,<,>,~,[,] " everything wraps
     "             | | | | | | | | |
     "             | | | | | | | | +-- "]" Insert and Replace
     "             | | | | | | | +-- "[" Insert and Replace
     "             | | | | | | +-- "~" Normal
     "             | | | | | +-- <Right> Normal and Visual
     "             | | | | +-- <Left> Normal and Visual
     "             | | | +-- "l" Normal and Visual (not recommended)
     "             | | +-- "h" Normal and Visual (not recommended)
     "             | +-- <Space> Normal and Visual
     "             +-- <BS> Normal and Visual
     set wildmenu " turn on command line completion wild style
     " ignore these list file extensions
     set wildignore=*.dll,*.o,*.obj,*.bak,*.exe,*.pyc,
                    \*.jpg,*.gif,*.png
     set wildmode=list:longest " turn on wild mode huge list
" }

" Vim UI {
"    set cursorcolumn " highlight the current column
"    set cursorline " highlight current line
"    set incsearch " BUT do highlight as you type you
                   " search phrase
     set laststatus=2 " always show the status line
     set lazyredraw " do not redraw while running macros
     set linespace=0 " don't insert any extra pixel lines
                      " betweens rows
"    set list " we do what to show tabs, to ensure we get them
              " out of my files
"    set listchars=tab:>-,trail:- " show tabs and trailing
    set matchtime=5 " how many tenths of a second to blink
                     " matching brackets for
"    set nohlsearch " do not highlight searched for phrases
"    set nostartofline " leave my cursor where it was
    set novisualbell " don't blink
"   set number " turn on line numbers
    set numberwidth=5 " We are good up to 99999 lines
"    set report=0 " tell us when anything is changed via :...
    set ruler " Always show current positions along the bottom
    set scrolloff=10 " Keep 10 lines (top/bottom) for scope
    set shortmess=aOstT " shortens messages to avoid
                         " 'press a key' prompt
    set showcmd " show the command being typed
    set showmatch " show matching brackets
    set sidescrolloff=10 " Keep 5 lines at the size
    set statusline=%F%m%r%h%w[%L][%{&ff}]%y[%p%%][%04l,%04v]
    "              | | | | |  |   |      |  |     |    |
    "              | | | | |  |   |      |  |     |    + current
    "              | | | | |  |   |      |  |     |       column
    "              | | | | |  |   |      |  |     +-- current line
    "              | | | | |  |   |      |  +-- current % into file
    "              | | | | |  |   |      +-- current syntax in
    "              | | | | |  |   |          square brackets
    "              | | | | |  |   +-- current fileformat
    "              | | | | |  +-- number of lines
    "              | | | | +-- preview flag in square brackets
    "              | | | +-- help flag in square brackets
    "              | | +-- readonly flag in square brackets
    "              | +-- rodified flag in square brackets
    "              +-- full path to file in the buffer
" }

" Folding {
    set foldenable " Turn on folding
    set foldmarker={{{,}}} " Fold C style code (only use this as default
                        " if you use a high foldlevel)
    set foldmethod=marker " Fold on the marker
    set foldlevel=0 " Don't autounfold anything (but I can still
                      " fold/unfold manually)
    set foldopen=block,hor,mark,percent,quickfix,tag " what movements
                                                      " open folds
    function SimpleFoldText() " {
        return getline(v:foldstart).' '
    endfunction " }
"   set foldtext=SimpleFoldText() " Custom fold text function
                                   " (cleaner than default)
" }

" Plugin Settings {
    let b:match_ignorecase = 1 " case is stupid
    let perl_extended_vars=1 " highlight advanced perl vars
                              " inside strings

    " TagList Settings {
        let Tlist_Auto_Open=0 " let the tag list open automagically
        let Tlist_Compact_Format = 1 " show small menu
        let Tlist_Ctags_Cmd = 'ctags' " location of ctags
        let Tlist_Enable_Fold_Column = 0 " do show folding tree
        let Tlist_Exist_OnlyWindow = 1 " if you are the last, kill
                                        " yourself
        let Tlist_File_Fold_Auto_Close = 0 " fold closed other trees
        let Tlist_Sort_Type = "name" " order by
        let Tlist_Use_Right_Window = 1 " split to the right side
                                        " of the screen
        let Tlist_WinWidth = 40 " 40 cols wide, so i can (almost always)
                                 " read my functions
        " Language Specifics {
            " just functions and classes please
            let tlist_aspjscript_settings = 'asp;f:function;c:class'
            " just functions and subs please
            let tlist_aspvbs_settings = 'asp;f:function;s:sub' 
            " don't show variables in freaking php
            let tlist_php_settings = 'php;c:class;d:constant;f:function' 
            " just functions and classes please
            let tlist_vb_settings = 'asp;f:function;c:class' 
        " }
    " }
" }

" Mappings {
    " ROT13 - fun
    map <F12> ggVGg?

    " space / shift-space scroll in normal mode
"   noremap <S-space> <C-b>
"   noremap <space> <C-f>

    " Make Arrow Keys Useful Again {
"       map <down> <ESC>:bn<RETURN>
"       map <left> <ESC>:NERDTreeToggle<RETURN>
"       map <right> <ESC>:Tlist<RETURN>
"       map <up> <ESC>:bp<RETURN>
    " }
" }

" Text Formatting/Layout {
    set modeline " Allow use of modelines
    set completeopt= " don't use a pop up menu for completions
                          " and let gq format comments
    set ignorecase " case insensitive by default
    set infercase " case inferred by default
    set nowrap " do not wrap line
    set smartcase " if there are caps, go case-sensitive
"   set formatoptions=rq " Automatically insert comment leader on return,
"   set shiftround " when at 3 spaces, and I hit > ... go to 4, not 5
"   set expandtab " no real tabs please!
"   set shiftwidth=4 " auto-indent amount when using cindent,
                      " >>, << and stuff like that
"   set softtabstop=4 " when hitting tab or backspace, how many spaces
                       "should a tab be (see expandtab)
"   set tabstop=8 " real tabs should be 8, and they will show with
                   " set list on
" }   

" Highlights {
    highlight ExtraWhiteSpace ctermbg=darkgreen guibg=lightgreen
    match ExtraWhiteSpace /\s\+$/
" }
