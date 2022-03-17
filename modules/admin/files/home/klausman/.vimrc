" These are the basics. The autocmd-loaded files further down might
" modify some of these
filetype on

" The colorscheme for vim, gvim ovverides this (see .gvimrc)
colorscheme wombat256modmod

" Make % recognize <p>/</p> and others
source $VIMRUNTIME/macros/matchit.vim

set backspace=2        " Allow backspacing over everything.
set bg=dark            " dark background
set cf                 " error file and error jumping
set clipboard+=unnamed " Use clipboad for yanking etc
set ek                 " Escapekeys (everything can be used in Ins-Mode)
set fo=cqrt            " commentwrap, gq-formatting, auto-comment, textwrap
set laststatus=2       " always show the status bar
set listchars=tab:>·,trail:·
set lz                 " do not redraw when executing macro (lazy)
set magic              " Extended Regexen for / and :s/
set matchpairs=(:),{:},[:],<:>
set modeline
set modelines=10       " Maximum context to search for same
set mouse=             " Don't interpret mouse clicks (c&p) in vim
set nocp               " Noncompatible.
set noeb               " No bell for error messages
set nofoldenable
set nojoinspaces       " I even hate single spaces, double even more so
set nostartofline      " Stay in current column when paging
set pt=<F11>           " paste-toggle
set report=0           " Be verbose/chatty about changes
set ru                 " Ruler (cursor position) (lazy)
set shm=at             " short messages (abbrev all, truncate if needed
set showcmd            " Show command status in ruler
set showmode           " show current mode in statusline
set title
set titlestring=%F\ %r\ [%n]\ %LL\ %p%%
set ttyfast            " My terminals are fast. All of 'em.
set vb                 " visual bell
set whichwrap=<,>,[,]  " Make  these movements pass over <cr>
set wildchar=<TAB>     " It's called tabcompletion for a reason
set wildmenu

syntax on
" This makes 'J' join lines wothout *ever* adding whitespace
nmap J gJ

" Various tweaks for certain filetypes
if !exists("autocommands_loaded")
  let autocommands_loaded = 1
  autocmd BufRead,BufNewFile,FileReadPost *.py source ~/.vim/python
  autocmd BufRead,BufNewFile,FileReadPost Makefile source ~/.vim/makefiles
  autocmd BufRead,BufNewFile,FileReadPost *.txt source ~/.vim/textfile
endif

" Highlight 'hard space' (0xFF)
highlight BadWhitespace ctermbg=darkgreen guibg=darkgreen
match BadWhitespace / /
