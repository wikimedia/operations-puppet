set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab
set expandtab
set autoindent
set smartindent
autocmd BufRead,BufEnter,BufNewFile /*/.git/COMMIT_EDITMSG setlocal textwidth=70

" Make tabs more obvious
set list
set listchars=eol:⏎,tab:▸·,trail:␠,nbsp:⎵

filetype plugin indent on    " required

colors elflord
