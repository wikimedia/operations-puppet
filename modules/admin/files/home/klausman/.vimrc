" These are the basics. The autocmd-loaded files further down might
" modify some of these
filetype on

" Make % recognize <p>/</p> and others
source $VIMRUNTIME/macros/matchit.vim

" This makes 'J' join lines wothout *ever* adding whitespace
nmap J gJ

" Options
set nocp " Noncompatible.
set ek " Escapekeys (everything can be used in Ins-Mode)
set cf " error file and error jumping
set clipboard+=unnamed " Use clipboad for yanking etc
set ru " Ruler (cursor position) (lazy)
set vb " visual bell
set wmnu " wildmenu, enhanced tab-completion for cmdline
set noeb " No bell for error messages
set fo=cqrt " commentwrap, gq-formatting, auto-comment, textwrap
set shm=at " short messages (abbrev all, truncate if needed
"set digraph " Might be useful when not having a compose-key
set bg=dark " dark background
set showcmd " Show command status in ruler
set matchpairs=(:),{:},[:],<:> " self-explanatory
set ttyfast " My terminals are fast. All of 'em.
set pt=<F11> " paste-toggle
if exists("g:loaded_bracketed_paste")
  finish
endif
let g:loaded_bracketed_paste = 1

let &t_ti .= "\<Esc>[?2004h"
let &t_te = "\e[?2004l" . &t_te

function! XTermPasteBegin(ret)
  set pastetoggle=<f29>
  set paste
  return a:ret
endfunction

execute "set <f28>=\<Esc>[200~"
execute "set <f29>=\<Esc>[201~"
map <expr> <f28> XTermPasteBegin("i")
imap <expr> <f28> XTermPasteBegin("")
vmap <expr> <f28> XTermPasteBegin("c")
cmap <f28> <nop>
cmap <f29> <nop>
" how to show nonprintables in list mode
"set listchars=eol:$,tab:>-,extends:+,precedes:+
set listchars=tab:>·,trail:·
set nojoinspaces " I even hate single spaces, double even more so
set laststatus=2 " always show the status bar
set magic " Extended Regexen for / and :s/
set modeline " Use modelines
set modelines=10 " Maximum context to search for same
set report=0 " Be verbose/chatty about changes
set showmode " show current mode in statusline
set nostartofline " Stay in current column when paging
set wildchar=<TAB> " It's called tabcompletion for a reason
set wildmenu " wild menu
set whichwrap=<,>,[,] " Make  these movements pass over <cr>
set lz " do not redraw when executing macro (lazy)
set backspace=2 " Allow backspacing over everything.
"set statusline=%F%m%r%h%w\ [%1{&ff}/%Y]\ [\%03.3b\ 0x\%02.2B]
set nofoldenable " I don't like folding
set smartindent
set autoindent

" Commands
syntax on

" Various tweaks for certain filetypes
if !exists("autocommands_loaded")
  let autocommands_loaded = 1
  autocmd BufRead,BufNewFile,FileReadPost Makefile source ~/.vim/makefiles
endif

" The colorscheme for vim, gvim ovverides this (see .gvimrc)
colorscheme wombat256modmod

set title
set titlestring=%F\ %r\ [%n]\ %LL\ %p%%

" This should be near the end, after all other mumbo-jumbo has been done.
highlight BadWhitespace ctermbg=darkgreen guibg=darkgreen
match BadWhitespace / /

let g:gitgutter_override_sign_column_highlight = 0

" Disable all blinking:
:set guicursor+=a:blinkon0

set directory=$HOME/.vim/swapfiles//
