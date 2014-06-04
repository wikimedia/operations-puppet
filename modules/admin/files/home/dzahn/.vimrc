syntax on
set number
" Wikimedia style uses 4 spaces for indentation
autocmd BufRead */wmf/puppet/* set sw=4 ts=4 et

set tabstop=4
set shiftwidth=4
set expandtab
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()
