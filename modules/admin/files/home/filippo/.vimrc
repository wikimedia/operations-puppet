set nocompatible

syntax on
filetype on
filetype indent on
filetype plugin on
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set backspace=indent,eol,start
set visualbell
set autoindent
set smartindent
set showmatch
set showcmd
set showmode
set ruler
set hlsearch
set incsearch
set scrolloff=10
set numberwidth=1
set background=dark
set modeline
set hidden
set textwidth=79
set wildmode=longest,list

" Highlighting columns 81 and 82
function! HighlightTooLongLines()
  highlight def link RightMargin Error
  if &textwidth != 0
    exec 'match RightMargin /\%<' . (&textwidth + 3) . 'v.\%>' . (&textwidth + 1) . 'v/'
  endif
endfunction

augroup filetypedetect
au BufNewFile,BufRead * call HighlightTooLongLines()
augroup END
autocmd BufEnter ?akefile* set noet ts=8 sw=8 nocindent listchars=trail:\ 

set list
" hilight tabs and trailing whitespaces as list chars
set listchars=tab:\ \ ,trail:\ ,extends:»,precedes:«
if &background == "dark"
  highlight SpecialKey ctermbg=Red guibg=Red
else
  highlight SpecialKey ctermbg=Yellow guibg=Yellow
end
