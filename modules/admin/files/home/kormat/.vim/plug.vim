call plug#begin('~/.vim/plugged')

Plug 'junegunn/vim-plug' " Install docs for vim-plug
Plug 'tpope/vim-sensible'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'patstockwell/vim-monokai-tasty'

let s:localplugrc = expand("~/.vim/plug.local.vim")
if filereadable(s:localplugrc)
  exe "source " . s:localplugrc
endif

call plug#end()

if !empty(globpath(&rtp, 'colors/vim-monokai-tasty.vim'))
  colorscheme vim-monokai-tasty
  let g:airline_theme='monokai_tasty'
endif

let g:airline_powerline_fonts = 1
let g:airline_section_x = ''
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#branch#enabled = 0

" For https://github.com/ctrlpvim/ctrlp.vim
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
let g:ctrlp_open_multiple_files = 'vjr'
