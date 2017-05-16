" Vim Compiler File
" Compiler:	php
" Maintainer:	Mikolaj Machowski <mikmach@wp.pl>
" Last Change:  2007-04-16 Bryan Davis <bpd@keynetics.com>
   
if exists("current_compiler")
    finish
endif
let current_compiler = "php"
  
if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim


" Running :make will run php's lint filter over the currently
" opened file.
" your PHP cli (or cgi) executable may be different
CompilerSet makeprg=php\ \-\l\ %\\\|\ grep\ '\ on\ line\ '

" Error format seems to change between versions, if this script
" doesn't seem to work, see if the format is incorrect
" Parse error: syntax error, unexpected $end, expecting ',' or ';' in foo.php
" on line 8
CompilerSet errorformat=%*[^:]:\ %m\ in\ %f\ on\ line\ %l


let &cpo = s:cpo_save
unlet s:cpo_save
