set number
inoremap jj <Esc>
autocmd BufWritePre *.pp :%s/\s\+$//e
autocmd BufNewFile,BufRead *.pp set filetype=ruby
syntax on
set background=dark
set nocompatible
filetype indent plugin on
set hidden
set showcmd
set showmatch
set hlsearch
set backspace=indent,eol,start
set autoindent
set nostartofline
set ruler
set laststatus=2
set confirm
set cmdheight=2
set tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
set cul
set wildmenu
set foldenable
set clipboard=unnamed
hi CursorLine   cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white
hi CursorColumn cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white
nnoremap <Leader>c :set cursorline! cursorcolumn!<CR>

autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* loadview
" let &t_SI = "\<Esc>]50;CursorShape=1\x7"
" let &t_SR = "\<Esc>]50;CursorShape=2\x7"
" let &t_EI = "\<Esc>]50;CursorShape=0\x7"
"
augroup BgHighlight
    autocmd!
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
augroup END
