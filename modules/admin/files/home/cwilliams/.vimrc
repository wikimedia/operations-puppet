syntax on
colorscheme slate
highlight RedundantWhitespace ctermbg=red guibg=red
match RedundantWhitespace /\s\+$\|\t/
autocmd BufWritePre * :%s/\s\+$//e
autocmd BufWritePre *Containerfile :%s/\s\+$//e

set ai ts=4 sw=4 sts=4 expandtab modeline
set smarttab ruler switchbuf=usetab
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
set showtabline=2 nocompatible
set pastetoggle=<F4>
set cc=120

set tabpagemax=100
autocmd VimEnter * if !&diff | tab all | tabfirst | endif

map <F2> :tabp<CR>
map <F3> :tabn<CR>
map <F5> :set list!<CR>
map <F6> :set nu!<CR>
map <F7> :set wrap!<CR>

noremap <F2> :tabp<CR>
noremap <F3> :tabn<CR>
noremap <F5> :set list!<CR>
noremap <F6> :set nu!<CR>
noremap <F7> :set wrap!<CR>

inoremap <F5> <C-o>:set list!<CR>
inoremap <F6> <C-o>:set nu!<CR>
inoremap <F7> <C-o>:set wrap!<CR>

cnoremap <F5> <C-c>:set list!<CR>
cnoremap <F6> <C-c>:set nu!<CR>
cnoremap <F7> <C-c>:set wrap!<CR>

