" This must be first, because it changes other options as side effect
set nocompatible

"Plugin loading system
call pathogen#infect()
syntax on

filetype plugin indent on

"Makes arrow key navigation sane...
set whichwrap+=<,>,[,]

"make search case insensitive
set ic

"fuck you escape key
map! ii <Esc> " map ii to Esc
map! ;; <Esc> " map ;; to Esc

nmap <c-o> <Esc>:w
"exit with inpunity no prompt just die
nmap <c-x> <Esc>:q<CR><CR>
nmap <c-a> <Esc>:Ack!

" Map Ctrl-A -> Start of line, Ctrl-E -> End of line
"yes ...this is crazy...
map <C-a> <Home>
map <C-e> <End>

" Text after a double-quote is a comment
set ruler
set tabstop=4
set shiftwidth=4
set expandtab

set list listchars=tab:▷⋅,trail:⋅,nbsp:⋅
set statusline=%F%m%r%h%w\ [TYPE=%Y\ %{&ff}]\
\ [%l/%L\ (%p%%)
au FileType py set autoindent
au FileType py set smartindent

" PEP-8 Friendly
au FileType py set textwidth=79
