" THIS FILE IS MANAGED BY PUPPET
"
" ~/.vimrc for Antoine 'hashar' Musso
"
" Most is copy pasted from https://github.com/hashar/alix/
"

let mapleader=","

syntax on
set background=dark

" highlight trailing whitespaces with a red background
highlight ExtraWhitespace ctermbg=red guibg=red
autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
call matchadd('ExtraWhitespace', '\s\+$')

" highlight non breaking spaces (on Mac: alt+space)
highlight NoBreakSpace ctermbg=cyan guibg=cyan
autocmd ColorScheme * highlight NoBreakSpace ctermbg=cyan guibg=cyan
call matchadd('NoBreakSpace', ' ')

" Ultimately make php boolean keywords true/false to be green/red
autocmd Syntax * syn keyword phpBooleanTrue true contained
autocmd Syntax * syn keyword phpBooleanFalse false contained
autocmd Syntax * syn cluster phpClConst remove=phpBoolean
autocmd Syntax * syn cluster phpClConst add=phpBooleanTrue,phpBooleanFalse
autocmd Syntax * highlight phpBooleanTrue ctermfg=darkGreen guibg=darkGreen
autocmd Syntax * highlight phpBooleanFalse ctermfg=darkRed guibg=darkRed

" Override color for "String" types
autocmd ColorScheme * highlight String ctermfg=Magenta

" erb magic
autocmd BufRead *.conf.erb set ft=eruby.dosini
autocmd BufRead *.cnf.erb set ft=eruby.dosini
autocmd BufRead *.ini.erb set ft=eruby.dosini
autocmd BufRead *.ini.erb set ft=eruby.dosini
autocmd BufRead *.js.erb set ft=eruby.javascript
autocmd BufRead *.py.erb set ft=eruby.python
autocmd BufRead *.sh.erb set ft=eruby.sh

set hlsearch
set smartcase

set ruler

" fancy tab completion from command line
set wildmenu
set wildmode=list:longest

" Make search case agnostic
set ignorecase
" Unless search string has an upper case character
set smartcase

set showcmd

set foldmethod=syntax
set foldlevelstart=99

nnoremap <silent> <Space> @=(foldlevel('.')?'za':'l')<CR>
vnoremap <Space> zf
let php_folding = 2
let javaScript_fold = 1
let g:xml_syntax_folding = 1
let perl_fold = 1
let perl_fold_blocks = 1

" shell folding
"   1 functions
"   2 heredoc
"   4 ifdofor
let sh_fold_enabled = 7
