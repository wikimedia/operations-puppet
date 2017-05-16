" bd808's handy vimrc

" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

let mapleader = "\\"      " use \ as leader char (default, but be safe)
let maplocalleader = ","  " use , as leader for scripts that are smart

" path to user's vim extras relative to vimrc location
" this is a helper for running as another user and pointing to this vimrc
let $VIMCONF=fnamemodify(expand($MYVIMRC), ":h")."/.vim"
set runtimepath+=$VIMCONF,$VIMCONF/after

" pathogen {{{
" To disable a plugin, add it's bundle name to the following list
let g:pathogen_disabled = []

" initialize tpope's awesome keep-your-.vim-dir-neat plugin
" see https://github.com/tpope/vim-pathogen
filetype on
filetype off
silent! call pathogen#helptags()
silent! call pathogen#runtime_append_all_bundles()
filetype plugin indent on
" }}}

" basic formatting {{{
set shiftwidth=4        " I have no idea why you would use anything else
set softtabstop=4       " backspace over a shift width
set tabstop=4           " tabs are for shifting
set expandtab           " but hard tabs are the devil
set smarttab            " initial tab based on shiftwidth
set shiftround          " indent in multiples of shiftwidth
set textwidth=78        " I hate long lines
set autoindent          " always set autoindenting on
set smartindent         " be smart about indenting new lines
" but be smarter about indenting comments
inoremap # X#
" cindent settings
set cinkeys=0{,0},:,!^F,!<Tab>,o,O,e
set cinoptions=>1s,n-1s,:1s,=1s,(2s,+2s
set formatoptions=croq  " wrap comments, insert leaders and format with gq
try
set formatoptions+=j    " remove extra comment leaders when joining lines
catch
endtry
set formatoptions+=n    " recognize numbered lists when formatting
set formatoptions+=1    " don't end lines with single letter words
set formatoptions+=b    " don't break existing long lines
set formatoptions+=t    " auto-wrap text too
" }}}

" backups, swap and history {{{
set nobackup            " don't keep a backup file
set nowritebackup       " seriously, no backup file
set viminfo='10,f1,<50,:50,n~/.viminfo
                        " marks for 10 files
                        " store file marks
                        " max 50 lines for each register
                        " remember 50 commands
                        " write to ~/.viminfo
set history=50          " keep 50 lines of command line history
" }}}

" wildcards and menus {{{
set wildmenu            " enhanced command-line completion
set wildignore=*~,*.bak,*.o,*.class,*.pyc,.svn,.git,.hg,.bzr
set wildmode=longest:full " longest common string + wildmenu
set wildchar=<Tab>      " wildcard completion key
set wildcharm=<C-Z>     " wildcard substitute inside macros
source $VIMRUNTIME/menu.vim " load menu files like we were a gui
" open menu with <F4>
map <F4> :emenu <C-Z>
" }}}

" status line, commands and splitters {{{
set laststatus=2        " always show status line
set shortmess=atI       " always show short messages
set showcmd             " display incomplete commands
set fillchars=vert:\ ,stl:\ ,stlnc:\  "no funny fill chars in splitters
set splitbelow
set splitright

function! SyntaxItem()
  return synIDattr(synID(line("."),col("."),1),"name")
endfunction

set statusline =
set statusline +=%-2.2n             " buffer number
set statusline +=\ %<%F             " full path
set statusline +=\ [%Y%R%W]         " filetype, readonly?, preview?
set statusline +=%{'~'[&pm=='']}    " patch mode?
set statusline +=%M                 " Modified?
set statusline +=%=                 " float right
set statusline +=%#error#%{&paste?'[paste]':''}%* " Paste mode?
set statusline +=\ %{&ff}           " file format
set statusline +=\ %{&fenc}         " encoding
set statusline +=\ %l,%c%V          " line, col-virt col (like :set ruler)
" }}}

" encoding and charsets {{{
set encoding=utf-8      " you don't use utf-8? ಠ_ಠ
let &termencoding = &encoding
try
  lang en_US
catch
endtry
set fileformats=unix,dos,mac  " preferred file format order
" }}}

" encryption {{{
try
  " :X encrypts with blowfish instead of lame ass zip
  set cm=blowfish
catch
endtry
" }}}

" search {{{
set ignorecase          " ignore case when searching
set smartcase           " don't ignore case if pattern contains uppercase
set incsearch           " do incremental searching
set hlsearch            " highlight matches
" toggle state of hlsearch and display status
nmap <C-n> <Esc>:set hlsearch! hlsearch?<CR>
" fancy substitute short cuts
nnoremap ;; :%s@@@g<Left><Left><Left>
nnoremap ;' :%s@@@gc<Left><Left><Left><Left>
vnoremap ;; :%s@@@g<Left><Left><Left>
vnoremap ;' :%s@@@gc<Left><Left><Left><Left>

" I don't like the default behavior of * and # requiring word boundaries
nnoremap <silent> * g*
nnoremap <silent> # g#

" Highlight word at cursor without changing position
nnoremap <leader>h *<C-O>
" find merge conflict markers
nmap <silent> <leader>cf <ESC>/\v^[<=>]{7}( .*\|$)<CR>
" }}}

" completion {{{
function! TabOrComplete()
  if (strpart(getline('.'), col('.')-2, 1) =~ '^\W\?$')
    return "\<Tab>"
  else
    return "\<C-n>"
  endif
endfunction
imap <Tab> <C-R>=TabOrComplete()<CR>
" }}}

" matchpairs {{{
set showmatch           " highlight matching brackets
set matchtime=5         " tenths of a second to blink matching brackets
" set matchpairs+=<:>
" jump to match with <tab> too
nnoremap <Tab> %
vnoremap <Tab> %
" }}}

" visual block tricks {{{
" wrap the block
vnoremap (  <ESC>`>a)<ESC>`<i(<ESC>
vnoremap {  <ESC>`>a}<ESC>`<i{<ESC>
vnoremap ""  <ESC>`>a"<ESC>`<i"<ESC>
vnoremap '  <ESC>`>a'<ESC>`<i'<ESC>
vnoremap `  <ESC>`>a`<ESC>`<i`<ESC>
vnoremap [  <ESC>`>a]<ESC>`<i[<ESC>
" reselect after indent/outdent
vnoremap < <gv
vnoremap > >gv
" }}}

" terminal setup {{{
set ttyfast
set term=builtin_xterm  " treat terminal as a plain xterm
" disable Background Color Erase (BCE)
" helps with tmux/screen redraw issues
set t_ut=

" disable alt buffer (raw) mode in terminal
" this keeps the screen form clearing on exit
set t_ti=
set t_te=

set visualbell          " don't beep, flash
set t_vb=
set noerrorbells        " don't beep damn it
" }}}

" movement {{{
set backspace=indent,eol,start  " backspace over everything in insert mode
set scrolloff=7         " keep 7 lines of context before/after cursor
set sidescrolloff=7     " keep 7 columns when scrolling side to side
set sidescroll=1        " don't snap cursor to mid screen
set whichwrap=<,>,h,l   " let cursors movement wrap to next/previous line
set nostartofline       " don't jump from column to column when changing lines

" make movement operate on screen lines rather than logical lines
nnoremap <silent> <Up>    gk
nnoremap <silent> <Down>  gj
nnoremap <silent> <Home>  g0
nnoremap <silent> <End>   g$
nnoremap <silent> k       gk
nnoremap <silent> j       gj
nnoremap <silent> 0       g0
nnoremap <silent> ^       g^
nnoremap <silent> $       g$
inoremap <silent> <Down>  <C-O>gj
inoremap <silent> <Up>    <C-O>gk

" Make <space> move page down
nnoremap <silent> <Space> <PageDown>
vnoremap <silent> <Space> <PageDown>

" Backspace and - map to page up
nnoremap <silent> <BS>    <PageUp>
nnoremap <silent> -       <PageUp>
vnoremap <silent> <BS>    <PageUp>
vnoremap <silent> -       <PageUp>

" emacs movement in command line! Blasphemous but awesome.
cnoremap <C-j> <t_kd>
cnoremap <C-k> <t_ku>
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
" omg let's do that everywhere
noremap <C-a> <Home>
noremap <C-e> <End>

" window movement shortcuts
nnoremap <C-j>    <C-W>j
nnoremap <C-k>    <C-W>k
nnoremap <C-h>    <C-W>h
nnoremap <C-l>    <C-W>l
nnoremap <M-Down> <C-W>j
nnoremap <M-Up>   <C-W>k
" }}}

" buffer traversal {{{
set hidden " Allow hiding dirty buffers
nnoremap <Leader>l        :ls<CR>:b <C-Z>
nnoremap <Leader>1        :1b<CR>
nnoremap <Leader>2        :2b<CR>
nnoremap <Leader>3        :3b<CR>
nnoremap <Leader>4        :4b<CR>
nnoremap <Leader>5        :5b<CR>
nnoremap <Leader>6        :6b<CR>
nnoremap <Leader>7        :7b<CR>
nnoremap <Leader>8        :8b<CR>
nnoremap <Leader>9        :9b<CR>
nnoremap <Leader>0        :10b<CR>
nnoremap <Leader>-        :b#<CR>
" cycle buffers with (shift/meta)-right/left
nnoremap <silent> <S-Right> :bn<CR>
nnoremap <silent> <S-Left>  :bp<CR>
nnoremap <silent> <M-Right> :bn<CR>
nnoremap <silent> <M-Left>  :bp<CR>
"}}}

" repeat {{{
" return cursor to where you started after performing action
nnoremap . .`[
" allow the . to execute once for each line of a visual selection
vnoremap . :normal .<CR>
" }}}

" show non-printing chars {{{
set list                " show unprintable characters
"set listchars=tab:»·,trail:¶,extends:❯,precedes:❮
set listchars=tab:›⠀,trail:␢,extends:❯,precedes:❮
" set showbreak=↪
" mark trailing spaces as an error
syntax match Error "\s\+$"
" mixed spaces and tabs is error
syntax match Error " \+\t"me=e-1
" lines over 78 chars are error colored
syntax match Error "\(^.\{79\}\)\@<=." contains=ALL containedin=ALL
" }}}

" folding {{{
set viewoptions=folds   " save fold state
set foldmethod=marker   " fold at markers
set nofoldenable        " folds off by default
" }}}

" quick fix {{{
" show all the fixes needed
nnoremap <Leader>cc   :botright cope<CR>
" Jump to the previous/next entry in the quickfix list
nnoremap <Leader>n    :cNext<CR>
nnoremap <Leader>p    :cprevious<CR>
" }}}

set report=0            " tell me when anything changes

set pastetoggle=<C-P>   " easy paste switch

set noicon              " don't modify icon text of the window
set notitle             " don't modify title of the window
set lazyredraw          " don't redraw during macros

" print format layout
set printoptions=left:0.5in,right:0.5in,top:0.25in,bottom:0.5in,paper:letter

set guicursor=n:blinkon0  " no blinking gvim cursor

set tags=.tags,tags       " use .tags for tags file

set nojoinspaces          " don't add spaces after period on gpip

" ack is better than grep {{{
set grepprg=ack\ --column
set grepformat=%f:%l:%c:%m
" }}}

" Don't use Ex mode, use Q for formatting
nnoremap Q gq

" make Y consistent with C and D
nnoremap Y y$

" Make p in Visual mode replace the selected text with the "" register.
vnoremap p <Esc>:let current_reg = @"<CR>gvs<C-R>=current_reg<CR><Esc>

" commands {{{
" when you forget to `sudo vim`, w!! to the rescue
cmap w!! %!sudo tee > /dev/null %

" }}}

" spelling {{{
" toggle spelling on/off
if has("spell")
  nnoremap <Leader>s :setlocal spell! spelllang=en_us<CR>

  function! BestSpellFix()
    if &spell
      normal 1z=
    else
      set spell
      normal 1z=
      set nospell
    endif
  endfunction
  command! BestSpellFix call BestSpellFix()
  nnoremap <Leader>z :BestSpellFix<CR>
endif
" }}}

if has("vertsplit")
  set equalalways
  set eadirection=ver
end

" modelines, what a pain in the butt {{{
" use the plugin from https://github.com/ciaranm/securemodelines instead
set nomodeline
set modelines=0
" }}}

" syntax highlighting {{{
syntax enable           " enable syntax highlighting
color desert            " set color scheme
set background=dark     " on a dark background
" }}}

" solarized {{{
let g:solarized_contrast="high"
let g:solarized_termcolors=16
color solarized         " set color scheme
" tweak solarized
hi clear CursorLine
hi CursorLine cterm=underline term=underline
hi! link CursorColumn CursorLine
hi clear IncSearch
hi IncSearch cterm=reverse ctermfg=1
hi clear SpellBad
hi SpellBad cterm=underline,bold
" }}}

if has("autocmd")
  augroup bd808 "{{{
    autocmd!
    " cd to the directory of the file in the active buffer
    if has("autochdir")
      set autochdir
    else
      autocmd BufEnter * silent! lcd %:p:h
    endif

    " ensure full syntax hilighting
    autocmd BufEnter * :syntax sync fromstart

    if version >= 700
      " underline current line in insert mode
      autocmd InsertEnter * setlocal cursorline
      autocmd InsertLeave * setlocal nocursorline
    endif

    " seriously, how amny times to I have to tell you not to beep?
    autocmd GUIEnter * set visualbell t_vb=
  augroup END "}}}

  augroup text "{{{
    au!
    " For all text files set 'textwidth' to 78 characters.
    autocmd FileType text setlocal textwidth=78
  augroup END "}}}

  augroup js "{{{
    au!
    autocmd BufNewFile,BufReadPost *.coffee setl foldmethod=indent nofoldenable
  augroup END "}}}

  augroup json "{{{
    au!
    autocmd BufRead,BufNewFile *.json set filetype=json
    autocmd FileType json setlocal formatoptions=tcq2l
    autocmd FileType json setlocal foldmethod=syntax
  augroup END "}}}

  augroup php "{{{
    au!
    autocmd BufNewFile,BufRead *.php.inc set filetype=php
    autocmd BufNewFile,BufRead *.phpt set filetype=php
    autocmd FileType php compiler php
    autocmd FileType php set omnifunc=phpcomplete#CompletePHP
    " I think that a js plugin was causing this, but just to be safe
    autocmd FileType php setlocal iskeyword-=\$
    let g:pdv_cfg_php4always = 0
    let g:pdv_cfg_php4guess = 0
    let g:PHP_removeCRwhenUnix = 1
    let g:PHP_vintage_case_default_indent = 1
    let g:PHP_BracesAtCodeLevel = 0
    let g:PHP_outdentphpescape = 0
    " double indent lines that continue from prior
    let g:PHP_continuation_indenting = 2
    " yuck. MW style says tabs not spaces.
    autocmd Filetype php setlocal noet
  augroup END "}}}

  augroup c "{{{
    au!
    " K&R'ish indent options
    autocmd FileType c setlocal cinoptions=>s,e0,n0,f0,{0,}0,^0,:0,=s,l1,b0,g0,hs,ps,to,is,+2s,c3,C0,/0,(2s,u0,U0,w1,W2s,m0,M0,j0,)20,*30,#0
    let c_syntax_for_h=1
  augroup END "}}}

  augroup python "{{{
    au!
    "let python_highlight_all=1
    let python_highlight_builtins = 1
    let python_highlight_exceptions = 1
    let python_highlight_space_errors = 1
    autocmd FileType python setlocal foldmethod=indent sw=4 ts=4 sts=4 et
    autocmd FileType python setlocal ft=python.django
    autocmd FileType python setlocal makeprg=python\ -c\ \"import\ py_compile,sys;\ sys.stderr=sys.stdout;\ py_compile.compile(r'%')\"
    autocmd FileType python setlocal efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m
  augroup END "}}}

  augroup html "{{{
    au!
    let g:xml_syntax_folding=1
    let html_use_css=1
    "let b:closetag_html_style=1
    autocmd Filetype html,htmldjango,xhtml,xml,xsl
        \ execute "source".$VIMCONF."/scripts/closetag.vim"
    autocmd Filetype html,htmldjango,xhtml,xml,xsl setlocal foldmethod=syntax
  augroup END "}}}

  augroup css "{{{
    au!
    "autocmd FileType css call Bender_ProgDefaults()
  augroup END "}}}

  augroup yaml "{{{
    au!
    autocmd FileType yaml setlocal sw=2 ts=2 sts=0 et
  augroup END "}}}

  augroup vcs "{{{
    au!
    " just type q to close the split
    autocmd User VCSBufferCreated
        \ silent! nmap <unique> <buffer> q :bwipeout<cr>

    " git commit edits
    autocmd BufRead COMMIT_EDITMSG setlocal noautochdir nosplitbelow nosplitright
    " open the git diff --cached output in a new split
    autocmd BufRead COMMIT_EDITMSG DiffGitCached | wincmd r | wincmd t
    " turn on spell checking
    autocmd BufRead COMMIT_EDITMSG setlocal spell spelllang=en_us
    " jump back to the top of the buffer to undo position memory
    autocmd BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
  augroup END "}}}

  augroup perl "{{{
    au!
    let perl_extended_vars=1 " highlight advanced perl vars inside strings
  augroup END "}}}

  augroup makefile "{{{
    au!
    " don't expand tabs to spaces in makefiles
    autocmd BufEnter [Mm]akefile* setlocal noet
  augroup END "}}}

  augroup rst "{{{
    au!
    let g:riv_code_indicator=0
    let g:riv_create_link_pos='$'
    let g:riv_file_link_style=2
    let g:riv_highlight_code='python,c,javascript,vim,sh,php'
    autocmd BufNewFile,BufReadPost *.rst setl foldenable
  " }}}

  augroup spelling "{{{
    au!
    au FileType text,markdown,rst,textile setlocal spell spelllang=en_us
  augroup END "}}}

  augroup JumpCursorOnEdit "{{{
    au!
    autocmd BufReadPost *
        \ if expand("<afile>:p:h") !=? $TEMP |
        \   if line("'\"") > 1 && line("'\"") <= line("$") |
        \     let b:jumpToLine = line("'\"") |
        \     let b:doopenfold = 1 |
        \     if (foldlevel(b:jumpToLine) > foldlevel(b:jumpToLine - 1)) |
        \        let b:jumpToLine = b:jumpToLine - 1 |
        \        let b:doopenfold = 2 |
        \     endif |
        \     exe b:jumpToLine |
        \     unlet b:jumpToLine |
        \   endif |
        \ endif

    " Need to postpone using "zv" until after reading the modelines.
    autocmd BufWinEnter *
        \ if exists("b:doopenfold") |
        \   exe "normal zv" |
        \   if(b:doopenfold > 1) |
        \       exe  "+".1 |
        \   endif |
        \   unlet b:doopenfold |
        \ endif
  augroup END "}}}

  augroup VimConfig "{{{
    au!
    "reload vimrc after editing
    autocmd Filetype vim setlocal foldenable
    autocmd BufWritePost ~/.vimrc source ~/.vimrc
    autocmd BufWritePost vimrc    source ~/.vimrc
  augroup END "}}}

endif
" vim:set sw=2 ts=2 sts=2 et:
