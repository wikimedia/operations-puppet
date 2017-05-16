" php files

setlocal shiftwidth=2
setlocal tabstop=2
setlocal softtabstop=2
setlocal expandtab
setlocal textwidth=78
setlocal cino=>1s,n-1s,:1s,=1s,(2s,+2s
setlocal cink=0{,0},:,!^F,!<Tab>,o,O,e
setlocal formatoptions+=qroct

" use my php compiler script
compiler php

let php_sql_query=1
let php_baselib=1
let php_noShortTags=1
"let php_folding=1

" tweaks for php indenter
let PHP_removeCRwhenUnix=1

imap <C-o> <Esc>:set paste<CR>:exe PhpDoc()<CR>:set nopaste<CR>i
nmap <Leader>pd :exe PhpDoc()<CR>

" path for find commands (cwd + projects dir + pear)
" TODO: would be nice if this stayed in the same project (need cdp inside vim)
setlocal path=.,/usr/share/php
setlocal dictionary-=~/.vim/data/phpfunctions.txt
setlocal complete-=k complete+=k

" {{{ Autocompletion using the TAB key

" This function determines, wether we are on the start of the line text (then
" tab indents) or if we want to try autocompletion
func! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction

" Remap the tab key to select action with InsertTabWrapper
"inoremap <tab> <c-r>=InsertTabWrapper()<cr>

" }}} Autocompletion using the TAB key

" {{{ Alignment
if !exists("*PhpAlign")
  function! PhpAlign() range
      let l:paste = &g:paste
      let &g:paste = 0

      let l:line        = a:firstline
      let l:endline     = a:lastline
      let l:maxlength = 0
      while l:line <= l:endline
          if getline (l:line) =~ '^\s*\/\/.*$'
              let l:line = l:line + 1
              continue
          endif
          let l:index = substitute (getline (l:line), '^\s*\(.\{-\}\)\s*=>\{0,1\}.*$', '\1', "") 
          let l:indexlength = strlen (l:index)
          let l:maxlength = l:indexlength > l:maxlength ? l:indexlength : l:maxlength
          let l:line = l:line + 1
      endwhile

      let l:line = a:firstline
      let l:format = "%s%-" . l:maxlength . "s %s %s"

      while l:line <= l:endline
          if getline (l:line) =~ '^\s*\/\/.*$'
              let l:line = l:line + 1
              continue
          endif
          let l:linestart = substitute (getline (l:line), '^\(\s*\).*', '\1', "")
          let l:linekey   = substitute (getline (l:line), '^\s*\(.\{-\}\) *=>\{0,1\}.*$', '\1', "")
          let l:linesep   = substitute (getline (l:line), '^\s*.* *\(=>\{0,1\}\).*$', '\1', "")
          let l:linevalue = substitute (getline (l:line), '^\s*.* *=>\{0,1\}\s*\(.*\)$', '\1', "")

          let l:newline = printf (l:format, l:linestart, l:linekey, l:linesep, l:linevalue)
          call setline (l:line, l:newline)
          let l:line = l:line + 1
      endwhile
      let &g:paste = l:paste
  endfunc
endif
" }}}

" {{{ (Un-)comment
if !exists("*PhpUnComment")
  function! PhpUnComment() range
      let l:paste = &g:paste
      let &g:paste = 0

      let l:line        = a:firstline
      let l:endline     = a:lastline

      while l:line <= l:endline
          if getline (l:line) =~ '^\s*\/\/.*$'
              let l:newline = substitute (getline (l:line), '^\(\s*\)\/\/ \(.*\).*$', '\1\2', '')
          else
              let l:newline = substitute (getline (l:line), '^\(\s*\)\(.*\)$', '\1// \2', '')
          endif
          call setline (l:line, l:newline)
          let l:line = l:line + 1
      endwhile

      let &g:paste = l:paste
  endfunc
endif
" }}}

if !exists('g:php_source_prefixes')
  let g:php_source_prefixes = [
      \ '/src/php/', '/src/main/php/', '/src/main/',
      \ '/src/test/php/', '/src/test/',
      \ '/src/', '/lib/', '/tests/',
      \ ]
endif

function! s:stripPrefix(path)
  let l:path = a:path
  for l:prefix in g:php_source_prefixes
    let l:cut = stridx(l:path, l:prefix)
    if l:cut != -1
      let l:path = strpart(l:path, l:cut + strlen(l:prefix))
      break
    endif
  endfor
  return l:path
endfunction "s:stripPrefix

function! s:trPath(path, char)
  return join(split(s:stripPrefix(a:path), '/'), a:char)
endfunction

function! TSkeleton_NAMESPACE()
  return s:trPath(expand('%:p:h'), '\')
endfunction "TSkeleton_NAMESPACE

function! TSkeleton_PACKAGE()
  return s:trPath(expand('%:p:h'), '_')
endfunction "TSkeleton_PACKAGE

function! TSkeleton_EXTENDS_IF_TEST()
  let l:name = expand('%:t:r')
  if matchend(l:name, 'Test') == strlen(l:name)
    return 'extends \PHPUnit_Framework_TestCase '
  else
    return ''
  endif
endfunction "TSkeleton_EXTENDS_IF_TEST
