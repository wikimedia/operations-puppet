syntax on
set mouse-=a
color ron
set nu
setlocal spell spelllang=en_gb
hi clear SpellBad
hi SpellBad cterm=underline
set spellcapcheck=''
"set nospell
au BufRead,BufNewFile *.nse set ft=lua
au BufRead,BufNewFile *.cf set ft=cf3
au BufRead,BufNewFile *.j2 set ft=jinja
call pathogen#infect()
"

set shiftwidth=2
set softtabstop=2
set tabstop=4
au Filetype python setl et ts=4 sw=4 softtabstop=4
au Filetype puppet setl et ts=4 sw=4 softtabstop=4
set shortmess-=tT
set autoindent
"set autowrite
set backspace=indent,eol,start
set cindent
set cinkeys=0{,0},0),:,!^F,o,O,e
set cinoptions=f0,{0,t0,(0,u0,w1,W1s,)60,*60
set cpo&vim
set diffopt+=icase,iwhite,filler
set encoding=utf8
set expandtab
set fileencoding=utf8
"set fileencodings=ucs-bom,utf-8,default
set foldmethod=syntax
set formatoptions=crn
set fdl=1
set guifont=Andale\ Mono:h13
set guioptions-=tT
set history=60
set hlsearch
set incsearch
set laststatus=2
set modeline
set modelines=5
"set mp=gmake
set nocompatible
"set runtimepath=$DEV/vim,$VIMRUNTIME
set ruler
set shiftround
set showcmd
set showmatch
set smartindent
set smarttab
set viminfo='20,\"80,c
filetype plugin indent on
hi PreProc ctermfg=Green
hi Normal guibg=grey95
if &term =~ "xteam.*"
    let &t_ti = &t_ti . "\e[?2004h"
    let &t_te = "\e[?2004l" . &t_te
    function XTermPasteBegin(ret)
        set pastetoggle=<Esc>[201~
        set paste
        return a:ret
    endfunction
    map <expr> <Esc>[200~ XTermPasteBegin("i")
    imap <expr> <Esc>[200~ XTermPasteBegin("")
    cmap <Esc>[200~ <Nop>
    cmap <Esc>[201~ <Nop>
endif

function! CleverTab()
    if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
  return "\<Tab>"
    else
	return "\<C-N>"
endfunction
inoremap <Tab> <C-R>=CleverTab()<CR>

function Py2()
  let g:syntastic_python_pylint_exe = '/usr/bin/pylint'
endfunction

function Py3()
  let g:syntastic_python_pylint_exe = '/usr/bin/pylint3'
  let g:syntastic_python_python_exe = '/usr/bin/python3'
  let g:syntastic_python_python_args = '-m py_compile'
endfunction

call Py3()
