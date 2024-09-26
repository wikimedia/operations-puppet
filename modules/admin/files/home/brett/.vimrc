syntax on
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set nojoinspaces

set relativenumber
set number

" Change into the dir of the file automatically
set autochdir

" I prefer new vertical splits to go right, just like i3/tmux
set splitright

" Turn off that annoying auto-commenting on new line
set formatoptions-=cro

" True Color
set termguicolors

" Read vim: settings in files
set modeline

" Fix hash symbols being de-indented when using cindent
set cinkeys-=0#
set indentkeys-=0#

" nvim defaults to irritating mouse-selection weirdness.
" I like vim's method
set mouse=

" Show tab characters - Keep the trailing space!
set list
set listchars=tab:→\ 

" Search down into subfolders
" Provides tab-completion for all file-related tasks
set path=$PWD/**

" Display all matching files when we tab complete
set wildmenu

" Make the title of the terminal window more useful
set title

" Tweaks for browsing
let g:netrw_banner=0        " disable annoying banner
let g:netrw_liststyle=3     " tree view

let mapleader = ","
let g:mapleader = ","

" Prevent infinite headaches
nmap Q <Nop>
" Toggle line numbers on/off (typically for easy mouse selection)
nmap <leader>n :set invnumber <bar> :set invrelativenumber<CR>
" Easy pane switching
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
nmap <leader>dg :diffget<CR>
nmap <leader>dp :diffput<CR>

" Remove trailing whitespace at end of line
nmap <leader>e :%s/\s\+$//e<CR>


augroup vimStartup
    au!

    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event handler
    autocmd BufReadPost *
        \ if line("'\"") >= 1 && line("'\"") <= line("$") |
        \   exe "normal! g`\"" |
        \ endif

augroup END

" Exotic file type extensions that are just common extensions under another
" name and don't have a syntax file.
augroup exotic_ft_exts
    autocmd BufRead,BufNewFile *.sls set filetype=yaml
    autocmd BufRead,BufNewFile Jenkinsfile set filetype=groovy
    autocmd BufRead,BufNewFile *.vtc set filetype=vcl
augroup END

augroup inactive_panes
    autocmd!
    autocmd WinEnter * set relativenumber number cursorline
    autocmd WinLeave * set norelativenumber nonumber nocursorline
augroup END

" Highlight any trailing whitespace. This must be after colorscheme settings,
" otherwise they might overwrite the settings
highlight ExtraWhitespace ctermbg=darkred guibg=darkred
match ExtraWhitespace /\s\+$/
