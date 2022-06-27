" minimal version of vimrc from https://code.p1k3.com/gitea/brennen/bpb-kit

" initial setup {{{

  set nocompatible

  " Temporarily disable modelines (like the one at the top of this file), per:
  " https://github.com/numirias/security/blob/master/doc/2019-06-04_ace-vim-neovim.md
  " TODO: Patch and/or look at securemodelines plugin
  set nomodeline

  " use comma for the leader key - this is used as a prefix for
  " a bunch of bindings, mostly in the keybindings section.  it's up
  " here for things that might require it before plugins are invoked,
  " such as vimwiki mappings.
  let mapleader = ","

  filetype plugin on
  filetype indent on

" }}}

" misc UI {{{

  " set the window title (usually to filename plus some metadata)
  set title

  " pretty colors
  set t_Co=256
  syntax on

  " pretty characters
  set encoding=utf-8

  " do not beep or flash at me
  " vb is needed to stop beep
  " t_vb sets visual bell action, we're nulling it out here
  " note also that this may need to be repeated in .gvimrc
  set visualbell
  set t_vb=

  " enable mouse for (a)ll, (n)ormal, (v)isual, (i)nsert, or (c)ommand line
  " mode - seems to work in most terminals
  set mouse=a

  " render a useful popup menu for right-click instead of extending
  " selection (good for spellchecking, etc.):
  set mousemodel=popup_setpos

  " let me delete stuff like crazy in insert mode
  set backspace=indent,eol,start

  " see :help virtualedit - you probably don't want this
  " set virtualedit=onemore

  " display commands as-typed + current position in file
  set showcmd
  set ruler

  " height of command line area - having it greater than one avoids
  " some hit-enter prompts
  set cmdheight=2

  " display a visual menu for tab-completion of files
  set wildmenu

  " keep lots of command-line history - 10000 is currently the max value:
  set history=10000

  " search:
  set incsearch
  set ignorecase
  set smartcase
  set wrapscan

  " for gvim.  no toolbar, otherwise these are the defaults
  " set guioptions=aegimrLt

  " include '-' in words.  counts for both movement commands and autocomplete.
  " to test, try moving across and autocompleting for some-words-bunched-up
  " this is an experiment - mainly i want to use inline dashes in identifiers
  " in markdown documents, and so forth
  set iskeyword+=-

" }}}

" file saving/loading/swap/backups {{{

  " read (unchanged) buffers when they're modified on filesystem.
  " this saves me a lot of time and agony because i switch git branches
  " constantly, but it might not be what you want.
  set autoread

  " disable swapfiles (you may not want this (but you probably do)):
  set noswapfile

" }}}

" whitespace {{{

  " display tabs and trailing spaces:
  set listchars=tab:⇾\ ,trail:·
  set list

  " display tab characters as 8 spaces, indent 2 spaces,
  " always use spaces instead of tabs:
  set tabstop=8
  set shiftwidth=2
  set softtabstop=2
  set expandtab
  set autoindent

  " for c code, no tab expansion, turn off softtabstop
  au FileType c setlocal noexpandtab
  au FileType c setlocal shiftwidth=8
  au FileType c setlocal softtabstop=0

  " turn off tab expansion for Makefiles and calendar files:
  au FileType make setlocal noexpandtab
  au FileType calendar setlocal noexpandtab

  " wrap entire words in markdown files
  " http://stackoverflow.com/questions/19624105/how-can-i-make-vim-break-lines-only-on-whitespace
  au FileType markdown setlocal wrap linebreak breakat&vim

" }}}

" keybindings {{{

  " wait longer than the default (1000ms) for keycodes and mapped keys:
  set timeoutlen=3000

  " F8 inserts an ISO-8601 datestamp (mnemonic: eight rhymes with date)
  " (used to open the options window; use :options for that)
  map <F8> :r !date -I<CR>kJ

  " ,F8 inserts a date with seconds precision
  map <Leader><F8> :r !date -Is<CR>kJ

  " ,td / ,tD do the same (mnemonic: toDay)
  map <Leader>td :r !date -I<CR>kJ
  map <Leader>tD :r !date -Is<CR>kJ

  imap <F8> <Esc><F8>

  " F9 toggles search highlighting and some other noise
  map <F9> :call <SID>Crosshairs()<CR>
  imap <F9> <Esc><F9>

  " F11 i'm leaving unbound because of fullscreen shortcuts in various
  " terminals and window managers

  " in normal or insert mode, <F12> copies all in buffer
  " in visual/select modes, it just yanks the selected bit
  nmap <F12> :%y+<CR>
  imap <F12> <Esc><F12>
  vmap <F12> y+

  " split lines under the cursor (modeled on, maybe, emacs?)
  map K i<CR><Esc>g;

  " visual select inner word
  nmap <Leader>v viW

  " jump to next, previous errors
  nmap <Leader>n :cnext<CR>
  nmap <Leader>p :cprev<CR>

  " reformat a paragraph
  nmap <Leader>q gqip
  map Q gq

  " tab navigation somewhat like firefox
  " http://vim.wikia.com/wiki/Alternative_tab_navigation
  nmap <C-S-Tab> :tabprevious<CR>
  nmap <C-Tab> :tabnext<CR>
  map <C-S-Tab> :tabprevious<CR>
  map <C-Tab> :tabnext<CR>
  imap <C-S-Tab> <Esc>:tabprevious<CR>i
  imap <C-Tab> <Esc>:tabnext<CR>i

  " new tab:
  nmap <Leader>tn :tabnew<CR>

  " run timeslice script for current file:
  nmap <Leader>ts :call TimesliceForFile()<CR>

  " split window navigation (ctrl-j/k, alt-arrows)
  map <C-J> <C-W>j<C-W>_
  map <M-Down> <C-W>j
  map <C-K> <C-W>k<C-W>_
  map <M-Up> <C-W>k
  map <M-Right> <C-W>l
  map <M-Left> <C-W>h

" }}}

" functions {{{

  " run the file through a custom filter, leaving the cursor at its original
  " location in the file (or close) - there might be a better way to do this,
  " but i don't know what it is
  function! s:RunFilter(filter)
    let l:currentline = line('.')
    execute ":%!" . a:filter
    execute ":" . l:currentline
  endfunction

  " do some normal-mode commands and return the cursor to its previous location
  function! s:ExecNormalAndReturnCursor(commands)
    let l:currentline = line('.')
    " see http://learnvimscriptthehardway.stevelosh.com/chapters/30.html
    execute "normal! " . a:commands
    execute ":" . l:currentline
  endfunction

  " add some display sugar that helps highlight cursor, searches, and
  " textwidth.  good for fiddling with alignment, reflowing text, etc.
  function! s:Crosshairs()
    set invhlsearch
    set invcursorcolumn
    set invcursorline

    " toggle a colorcolumn - will get weird if it's set outside this function
    if &colorcolumn == "+1"
      set colorcolumn=0
    else
      " i think this is relative to textwidth
      set colorcolumn=+1
    endif
  endfunction

  " cycle between no, absolute, and relative line numbers
  function! s:CycleLineNumbers()
    if (&number)
      set nonumber
      return
    endif

    if (&relativenumber)
      set number norelativenumber
    else
      set number relativenumber
    endif
  endfunction

  " this is pretty much horked from:
  " http://vim.wikia.com/wiki/Display_output_of_shell_commands_in_new_window
  function! s:CommandOutputInNewWindow(cmdline)
    echo a:cmdline
    let expanded_cmdline = a:cmdline
    for part in split(a:cmdline, ' ')
       if part[0] =~ '\v[%#<]'
          let expanded_part = fnameescape(expand(part))
          let expanded_cmdline = substitute(expanded_cmdline, part, expanded_part, '')
       endif
    endfor
    botright new
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap

    " uncomment calls here for debug info:
    " call setline(1, 'Command:  ' . a:cmdline)
    " call setline(2, 'Expanded: ' . expanded_cmdline)
    " display underline with = to length of previous line (pretty clever):
    " call setline(3, substitute(getline(2), '.', '=', 'g'))

    execute '$read !' . expanded_cmdline
    0delete " delete blank first line - get rid of this if you need debug msgs
    setlocal nomodifiable

    " enable folding with a column:
    setlocal foldenable
    setlocal foldcolumn=3
    1
  endfunction

  " tab drop (edit in existing or new tab) a file's real path, in case it is a
  " symlink - useful for, frex, symlinked .vimrc.  does wildcard expansion on
  " the path.  as usual, there are probably better ways to do all of this.
  function! s:TabDrop(path)
    let realpath = system('readlink -fn ' . shellescape(expand(a:path)))
    echom realpath
    execute 'tab drop ' . realpath
  endfunction

  " this is ridiculous
  " https://vi.stackexchange.com/questions/21825/how-to-insert-text-from-a-variable-at-current-cursor-position
  function! s:AppendAtCursor(string)
    execute "normal! a\<C-r>\<C-r>=a:string\<CR>\<Space>\<Esc>"
  endfunc

  function! s:AppendAtCursorAsVimwikiLink(string)
    let bracketed = '[[/' . a:string . ']]'
    call <SID>AppendAtCursor(bracketed)
  endfunc

" }}}

" folding {{{

  " turn off folding by default - i constantly open some file and have to
  " expand folds to see what's going on; this is easy to get back with zi
  set nofoldenable

  " use {{{ and }}} to denote a folded section (these can be adjusted by
  " setting foldmarker, but i'm sticking with the vim defaults):
  set foldmethod=marker

  " for custom foldline colors:
  " highlight Folded guibg=grey guifg=blue
  highlight FoldColumn ctermbg=darkgrey ctermfg=white guibg=darkgrey guifg=white

  " forked from: http://dhruvasagar.com/2013/03/28/vim-better-foldtext
  function! BPB_NeatFoldText()
    let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
    let lines_count = v:foldend - v:foldstart + 1
    let lines_count_text = '| ' . printf("%10s", lines_count . ' lines') . ' |'
    let foldchar = matchstr(&fillchars, 'fold:\zs.')
    let foldtextstart = strpart('+' . repeat(foldchar, v:foldlevel*2) . line, 0, (winwidth(0)*2)/3)
    let foldtextend = lines_count_text . repeat(foldchar, 8)
    let foldtextlength = strlen(substitute(foldtextstart . foldtextend, '.', 'x', 'g')) + &foldcolumn
    return foldtextstart . repeat(foldchar, winwidth(0)-foldtextlength) . foldtextend
  endfunction

  set foldtext=BPB_NeatFoldText()

" }}}
