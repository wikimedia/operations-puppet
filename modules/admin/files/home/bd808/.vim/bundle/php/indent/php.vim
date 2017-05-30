" BD808's hacked up php indent file
" Language:     PHP
" Author:       John Wellesz <John.wellesz (AT) teaser (DOT) fr>
" Author: Bryan Davis <bd808@bd808.com>
" URL:          http://www.2072productions.com/vim/indent/php.vim
" Last Change:  2011 October 23rd
" Newsletter:   http://www.2072productions.com/?to=php-indent-for-vim-newsletter.php
" Version:      1.35-bd808
"
" Changes: 1.35-bd808
" I took John Wellesz's php indenter, added html formatting from Johannes
" Zellner's html indenter and fixed up some stuff I didn't like about how it
" worked (specifically the select/case indenting of John's script and the
" indenting of multiline arrays and function declarations) I also gave
" Johannes' script responsibilty for indenting <script> blocks.
"
"
" Changes: 1.35         - New option: PHP_outdentSLComments to add extra
"                         indentation to single-line comments.
"
"
" Changes: 1.34         - Fix: string with /* would be treated as comment
"                         start when using single quote. (Thanks to Manic Chuang
"                         for the fix)
"
"
" Changes: 1.33         - Rewrote Switch(){case:default:} handling from
"                         scratch in a simpler more logical and infallible way...
"                       - Removed PHP_ANSI_indenting which is no longer
"                         needed.
"
"
" Changes: 1.32b        - Added PHP_ANSI_indenting and PHP_outdentphpescape
"                         options details to VIm documentation (:help php-indent).
"
"
" Changes: 1.32         - Added a new option: PHP_ANSI_indenting
"
"
" Changes: 1.31a        - Added a new option: PHP_outdentphpescape to indent
"                         PHP tags as the surrounding code.
"
" Changes: 1.30         - Fixed empty case/default indentation again :/
"                       - The ResetOptions() function will be called each time
"                         the ftplugin calls this script, previously it was
"                         executed on BufWinEnter and Syntax events.
"
"
" Changes: 1.29         - Fixed php file detection for ResetOptions() used for
"                         comments formatting. It now uses the same tests as
"                         filetype.vim. ResetOptions() will be correctly
"                         called for *.phtml, *.ctp and *.inc files.
"
"
" Changes: 1.28         - End HEREDOC delimiters were not considered as such
"                         if they were not followed by a ';'.
"                       - Added support for NOWDOC tags ($foo = <<<'bar')
"
"
" Changes: 1.27         - if a "case" was preceded by another "case" on the
"                         previous line, the second "case" was indented incorrectly.
"
" Changes: 1.26         - '/*' character sequences found on a line
"                         starting by a '#' were not dismissed by the indenting algorithm
"                         and could cause indentation problem in some cases.
"
"
" Changes: 1.25         - Fix some indentation errors on multi line conditions
"                         and multi line statements.
"                       - Fix when array indenting is broken and a closing
"                       ');' is placed at the start of the line, following
"                       lines will be indented correctly.
"                       - New option: PHP_vintage_case_default_indent (default off)
"                       - Minor fixes and optimizations.
"
"
" Changes: 1.24         - Added compatibility with the latest version of
"                         php.vim syntax file by Peter Hodge (http://www.vim.org/scripts/script.php?script_id=1571)
"                         This fixes wrong indentation and ultra-slow indenting
"                         on large php files...
"                       - Fixed spelling in comments.
"
"
" Changes: 1.23         - <script> html tags are now correctly indented the same
"                         way their content is.
"                       - <?.*?> (on a single line) PHP declarations are now
"                         always considered as non-PHP code and let untouched.
"
" Changes: 1.22         - PHPDoc comments are now indented according to the
"                         surrounding code.
"                       - This is also true for '/* */' multi-line comments
"                         when the second line begins by a '*'.
"                       - Single line '/* */' comments are also indented.
"
"
" Changes: 1.21         - 'try' and 'catch' were not registered as block starters so the '{'
"                         after a 'try' or 'catch' could be wrongly indented...
"                         (thanks to Gert Muller for finding this issue)
"
" Changes: 1.20         - Line beginning by a single or double quote followed
"                         by a space would cause problems... this was related
"                         to the bug correction of version 1.10 - Thanks to
"                         David Fishburn for finding this (he was lucky).
"                       - Changed the way this script set the 'formatoptions'
"                         setting, now it uses '-=' and '+='
"                       - New option: PHP_autoformatcomment (defaults to 1),
"                         if set to 0 the 'formatoptions' setting will not be
"                         altered.
"                       - When PHP_autoformatcomment is not 0, the 'comments'
"                         setting is set to the type of comments that PHP
"                         supports.
"
" Changes: 1.19         - Indentation of '*/' delimiter of '/**/' won't be broken by
"                         strings or '//' comments containing the "/*" character sequence.
"
" Changes: 1.182        - I Forgot to register 'interface' and 'abstract' as block starters so the '{'
"                         after them could be wrongly indented...
"
" Changes: 1.181        - I Forgot to register 'class' as a block starter so the '{'
"                         after a 'class' could be wrongly indented...
"
" Changes: 1.18         - No more problems with Vim 6.3 and UTF-8.
"                       - Opening braces "{" are always indented according to their block starter.
"
"                               Instead of:
"
"                                       if( $test
"                                           && $test2 )
"                                           {
"                                           }
"
"                               You have:
"
"                                       if( $test
"                                           && $test2 )
"                                       {
"                                       }
"
"
" Changes: 1.17         - Now following parts of split lines are indented:
"
"                               Instead of:
"
"                                       $foo=
"                                       "foo"
"                                       ."foo";
"
"                               You have:
"
"                                       $foo=
"                                           "foo"
"                                           ."foo";
"
"                       - If a "case : break;" was declared on a single line, the
"                         following "case" was not indented correctly.
"                       - If a </script> html tag was preceded by a "?>" it wasn't indented.
"                       - Some other minor corrections and improvements.
"
"
" Changes: 1.16         - Now starting and ending '*' of multiline '/* */' comments are aligned
"                         on the '*' of the '/*' comment starter.
"                       - Some code improvements that make indentation faster.
"
" Changes: 1.15         - Corrected some problems with the indentation of
"                         multiline "array()" declarations.
"
" Changes: 1.14         - Added auto-formatting for comments (using the Vim option formatoptions=qroc).
"                       - Added the script option PHP_BracesAtCodeLevel to
"                         indent the '{' and '}' at the same level than the
"                         code they contain.
"
" Changes: 1.13         - Some code cleaning and typo corrections (Thanks to
"                         Emanuele Giaquinta for his patches)
"
" Changes: 1.12         - The bug involving searchpair() and utf-8 encoding in Vim 6.3 will
"                         not make this script to hang but you'll have to be
"                         careful to not write '/* */' comments with other '/*'
"                         inside the comments else the indentation won't be correct.
"                         NOTE: This is true only if you are using utf-8 and vim 6.3.
"
" Changes: 1.11         - If the "case" of a "switch" wasn't alone on its line
"                         and if the "switch" was at col 0 (or at default indenting)
"                         the lines following the "case" were not indented.
"
" Changes: 1.10         - Lines beginning by a single or double quote were
"                         not indented in some cases.
"
" Changes: 1.09         - JavaScript code was not always directly indented.
"
" Changes: 1.08         - End comment tags '*/' are indented like start tags '/*'.
"                       - When typing a multiline comment, '}' are indented
"                         according to other commented '{'.
"                       - Added a new option 'PHP_removeCRwhenUnix' to
"                         automatically remove CR at end of lines when the file
"                         format is Unix.
"                       - Changed the file format of this very file to Unix.
"                       - This version seems to correct several issues some people
"                         had with 1.07.
"
" Changes: 1.07         - Added support for "Here document" tags:
"                          - HereDoc end tags are indented properly.
"                          - HereDoc content remains unchanged.
"                       - All the code that is outside PHP delimiters remains
"                         unchanged.
"                       - New feature: The content of <script.*> html tags is considered as PHP
"                         and indented according to the surrounding PHP code.
"                       - "else if" are detected as "elseif".
"                       - Multiline /**/ are indented when the user types it but
"                         remain unchanged when indenting from their beginning.
"                       - Fixed indenting of // and # comments.
"                       - php_sync_method option is set to 0 (fromstart).
"                         This is required for complex PHP scripts else the indent
"                         may fail.
"                       - Files with non PHP code at the beginning could alter the indent
"                         of the following PHP code.
"                       - Other minor improvements and corrections.
"
" Changes: 1.06:    - Switch block were no longer indented correctly...
"                   - Added an option to use a default indenting instead of 0.
"                     (whereas I still can't find any good reason to use it!)
"                   - A problem with ^\s*);\= lines where ending a non '{}'
"                     structure.
"                   - Changed script local variable to be buffer local
"                     variable instead.
"
" Changes: 1.05:    - Lines containing "<?php ?>" and "?> <?php"
"                     (start and end tag on the same line) are no
"                     longer indented at col 1 but as normal code.
"
" Changes: 1.04:    - Strings containing "//" could break the indenting
"                     algorithm.
"                   - When a '{}' block was at col 1, the second line of the
"                     block was not indented at all (because of a stupid
"                     optimization coupled with a bug).
"
" Changes: 1.03:    - Some indenting problems corrected: end of non '{}'
"                     structures was not detected in some cases. The part of
"                     code concerned have been re-written
"                   - PHP start tags were not indented at col 1
"                   - Wrong comment in the code have been corrected
"
" Changes: 1.02:    - The bug I was talking about in version 1.01 (right below) has
"                     been corrected :)
"                   - Also corrected another bug that could occur in
"                     some special cases.
"                   - I removed the debug mode left in 1.01 that could
"                     cause some Vim messages at loading if other script were
"                     bugged.
"
" Changes: 1.01:    - Some little bug corrections regarding automatic optimized
"                     mode that missed some tests and could break the indenting.
"                   - There is also a problem with complex non bracketed structures, when several
"                     else are following each other, the algorithm do not indent the way it
"                     should.
"                     That will be corrected in the next version.
"
"  If you find a bug, please e-mail me at John.wellesz (AT) teaser (DOT) fr
"  with an example of code that breaks the algorithm.
"
"
"       Thanks a lot for using this script.
"

" NOTE: This script must be used with PHP syntax ON and with the php syntax
"       script by Lutz Eymers (http://www.isp.de/data/php.vim ) or with the
"       script by Peter Hodge (http://www.vim.org/scripts/script.php?script_id=1571 )
"       the later is bunbdled by default with Vim 7.
"
"
"       In the case you have syntax errors in your script such as HereDoc end
"       identifiers not at col 1 you'll have to indent your file 2 times (This
"       script will automatically put HereDoc end identifiers at col 1 if
"       they are followed by a ';').
"

" NOTE: If you are editing files in Unix file format and that (by accident)
"       there are '\r' before new lines, this script won't be able to proceed
"       correctly and will make many mistakes because it won't be able to match
"       '\s*$' correctly.
"       So you have to remove those useless characters first with a command
"       like:
"
"       :%s /\r$//g
"
"       or simply 'let' the option PHP_removeCRwhenUnix to 1 and the script will
"       silently remove them when VIM load this script (at each bufread).
"
"
" Options: PHP_autoformatcomment = 0 to not enable autoformating of comment by
"          default, if set to 0, this script will let the 'formatoptions'
"          setting intact.
"
" Options: PHP_default_indenting = # of sw (default is 0), # of sw will be
"          added to the indent of each line of PHP code.
"
" Options: PHP_removeCRwhenUnix = 1 to make the script automatically remove CR
"          at end of lines (by default this option is unset), NOTE that you
"          MUST remove CR when the fileformat is UNIX else the indentation
"          won't be correct!
"
" Options: PHP_BracesAtCodeLevel = 1 to indent the '{' and '}' at the same
"          level than the code they contain.
"          Example:
"            Instead of:
"               if ($foo)
"               {
"                 foo();
"               }
"
"            You will write:
"               if ($foo)
"                 {
"                 foo();
"                 }
"
"          NOTE: The script will be a bit slower if you use this option because
"          some optimizations won't be available.
"
"
" Options: PHP_outdentphpescape = 0 (defaults to 1) to indent PHP tags as the
"          surrounding code.
"
" Options: PHP_vintage_case_default_indent = 1 (defaults to 0) to add
"          a meaningless indent before 'case:' and 'default":' statement in
"          switch blocks.
"
" Options: PHP_outdentSLComments = # of sw (defaults to 0) to outdent single
"          line PHP comments (// and # or /**/).
"
" Remove all the comments from this file:
" :%s /^\s*".*\({{{\|xxx\)\@<!\n\c//g
" }}}

" The 4 following lines prevent this script from being loaded several times
" per buffer. They also prevent the load of different indent scripts for PHP
" at the same time.
if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

" This script set the option php_sync_method of PHP syntax script to 0
" (fromstart indenting method) in order to have an accurate syntax.
" If you are using very big PHP files (which is a bad idea) you will
" experience slowings down while editing, if your code contains only PHP
" code you can comment the line below.
let php_sync_method = 0


" Apply options
if exists("PHP_default_indenting")
    let b:PHP_default_indenting = PHP_default_indenting * &sw
else
    let b:PHP_default_indenting = 0
endif

if exists("PHP_outdentSLComments")
    let b:PHP_outdentSLComments = PHP_outdentSLComments * &sw
else
    let b:PHP_outdentSLComments = 0
endif

if exists("PHP_BracesAtCodeLevel")
    let b:PHP_BracesAtCodeLevel = PHP_BracesAtCodeLevel
else
    let b:PHP_BracesAtCodeLevel = 0
endif

if exists("PHP_autoformatcomment")
    let b:PHP_autoformatcomment = PHP_autoformatcomment
else
    let b:PHP_autoformatcomment = 1
endif

if exists("PHP_outdentphpescape")
    let b:PHP_outdentphpescape = PHP_outdentphpescape
else
    let b:PHP_outdentphpescape = 1
endif

if exists("PHP_vintage_case_default_indent") && PHP_vintage_case_default_indent
    let b:PHP_vintage_case_default_indent = 1
else
    let b:PHP_vintage_case_default_indent = 0
endif

if exists("PHP_continuation_indenting")
    let b:PHP_continuation_indenting = PHP_continuation_indenting * &sw
else
    let b:PHP_continuation_indenting = &sw
endif

let b:PHP_lastindented = 0
let b:PHP_indentbeforelast = 0
let b:PHP_indentinghuge = 0
let b:PHP_CurrentIndentLevel = b:PHP_default_indenting
let b:PHP_LastIndentedWasComment = 0
let b:PHP_InsideMultilineComment = 0
" PHP code detect variables
let b:InPHPcode = 0
let b:InPHPcode_checked = 0
let b:InPHPcode_and_script = 0
let b:InPHPcode_tofind = ""
let b:PHP_oldchangetick = b:changedtick
let b:UserIsTypingComment = 0
let b:optionsset = 0

" The 4 options belows are overridden by indentexpr so they are always off
" anyway...
setlocal nosmartindent
setlocal noautoindent
setlocal nocindent
" autoindent must be on, so the line below is also useless...
setlocal nolisp

setlocal indentexpr=GetPhpHtmlIndent(v:lnum)
setlocal indentkeys=0{,0},0),:,!^F,o,O,e,*<Return>,=?>,=<?php,=*/,>

let s:searchpairflags = 'bWr'

" Clean CR when the file is in Unix format
if &fileformat == "unix" && exists("PHP_removeCRwhenUnix") && PHP_removeCRwhenUnix
    silent! %s/\r$//g
endif

" Only define the functions once per Vim session.
if exists("*GetPhpIndent")
    call ResetPhpOptions()
    finish " XXX -- comment this line for easy dev
endif

let s:endline= '\s*\%(//.*\|#.*\|/\*.*\*/\s*\)\=$'
let s:PHP_startindenttag = '<?\%(.*?>\)\@!\|<script[^>]*>\%(.*<\/script>\)\@!'
"setlocal debug=msg " XXX -- do not comment this line when modifying this file


function! GetLastRealCodeLNum(startline) " {{{
    "Inspired from the function SkipJavaBlanksAndComments by Toby Allsopp for indent/java.vim

    let lnum = a:startline

    " Used to indent <script.*> html tag correctly
    if b:GetLastRealCodeLNum_ADD && b:GetLastRealCodeLNum_ADD == lnum + 1
        let lnum = b:GetLastRealCodeLNum_ADD
    endif

    let old_lnum = lnum

    while lnum > 1
        let lnum = prevnonblank(lnum)
        let lastline = getline(lnum)

        " if we are inside an html <script> we must skip ?> tags to indent
        " everything as php
        if b:InPHPcode_and_script && lastline =~ '?>\s*$'
            let lnum = lnum - 1
        elseif lastline =~ '^\s*?>.*<?\%(php\)\=\s*$'
            let lnum = lnum - 1
        elseif lastline =~ '^\s*\%(//\|#\|/\*.*\*/\s*$\)'
            " if line is under comment
            let lnum = lnum - 1
        elseif lastline =~ '\*/\s*$'
            " skip multiline comments
            call cursor(lnum, 1)
            if lastline !~ '^\*/'
                call search('\*/', 'W')
                " position the cursor on the first */
            endif
            let lnum = searchpair('/\*', '', '\*/', s:searchpairflags, 'Skippmatch2()')
            " find the most outside /*

            let lastline = getline(lnum)
            if lastline =~ '^\s*/\*'
                " if line contains nothing but comment
                " do the job again on the line before (a comment can hide another...)
                let lnum = lnum - 1
            else
                break
            endif


        elseif lastline =~? '\%(//\s*\|?>.*\)\@<!<?\%(php\)\=\s*$\|^\s*<script\>'
            " skip non php code

            while lastline !~ '\(<?.*\)\@<!?>' && lnum > 1
                let lnum = lnum - 1
                let lastline = getline(lnum)
            endwhile
            if lastline =~ '^\s*?>'
                " if line contains nothing but end tag
                let lnum = lnum - 1
            else
                break
                " else there is something important before the ?>
            endif


            " Manage "here document" tags
        elseif lastline =~? '^\a\w*;\=$' && lastline !~? s:notPhpHereDoc
            " match the end of a heredoc
            let tofind=substitute( lastline, '\(\a\w*\);\=', '<<<''\\=\1''\\=$', '')
            while getline(lnum) !~? tofind && lnum > 1
                let lnum = lnum - 1
            endwhile
        else
            " if none of these were true then we are done
            break
        endif
    endwhile

    if lnum==1 && getline(lnum) !~ '<?'
        let lnum=0
    endif

    " This is to handle correctly end of script tags; to return the real last php
    " code line else a '?>' could be returned has last_line
    if b:InPHPcode_and_script && !b:InPHPcode
        let b:InPHPcode_and_script = 0
    endif

    "echom lnum
    "call getchar()


    return lnum
endfunction " }}}

function! Skippmatch2()

    let line = getline(".")

    " Skip opening /* if they are inside a string or preceded  by a single
    " line comment starter
    if line =~ "\\([\"']\\).*/\\*.*\\1" || line =~ '\%(//\|#\).*/\*'
        return 1
    else
        return 0
    endif
endfun

function! Skippmatch()  " {{{
    " the slowest instruction of this script, remove it and the script is 3
    " times faster but you may have troubles with '{' inside comments or strings
    " that will break the indent algorithm...
    let synname = synIDattr(synID(line("."), col("."), 0), "name")
    if synname == "Delimiter" || synname == "phpRegionDelimiter" || synname =~# "^phpParent" || synname == "phpArrayParens" || synname =~# '^php\%(Block\|Brace\)' || synname == "javaScriptBraces" || synname =~# "^phpComment" && b:UserIsTypingComment
        return 0
    else
"       echo "\"" . synname . "\"  " . getline(line("."));
"       call getchar()
        return 1
    endif
endfun " }}}

function! FindOpenBracket(lnum) " {{{
    " set the cursor to the start of the lnum line
    call cursor(a:lnum, 1)
    return searchpair('{', '', '}', 'bW', 'Skippmatch()')
endfun " }}}

function! FindTheIfOfAnElse (lnum, StopAfterFirstPrevElse) " {{{
    " A very clever recoursive function created by me (John Wellesz) that find the "if" corresponding to an
    " "else". This function can easily be adapted for other languages :)
    " 2010-07-25 -- Wow! it seems I was very proud of myself, I wouldn't write
    " such a comment nowadays.

    if getline(a:lnum) =~# '^\s*}\s*else\%(if\)\=\>'
        " we do this so we can find the opened bracket to speed up the process
        let beforeelse = a:lnum
    else
        let beforeelse = GetLastRealCodeLNum(a:lnum - 1)
    endif

    if !s:level
        let s:iftoskip = 0
    endif

    " If we've found another "else" then it means we need to skip the next "if"
    " we'll find.
    if getline(beforeelse) =~# '^\s*\%(}\s*\)\=else\%(\s*if\)\@!\>'
        let s:iftoskip = s:iftoskip + 1
    endif

    " A closing bracket? let skip the whole block to save some recursive calls
    if getline(beforeelse) =~ '^\s*}'
        let beforeelse = FindOpenBracket(beforeelse)

        " Put us on the block starter
        if getline(beforeelse) =~ '^\s*{'
            let beforeelse = GetLastRealCodeLNum(beforeelse - 1)
        endif
    endif


    " sometimes it's not useful to find the very first if of a long if elseif
    " chain. The previous elseif will be enough
    if !s:iftoskip && a:StopAfterFirstPrevElse && getline(beforeelse) =~# '^\s*\%([}]\s*\)\=else\%(if\)\=\>'
        return beforeelse
    endif

    " if there was an else, then there is a if...
    if getline(beforeelse) !~# '^\s*if\>' && beforeelse>1 || s:iftoskip && beforeelse>1

        if s:iftoskip && getline(beforeelse) =~# '^\s*if\>'
            let s:iftoskip = s:iftoskip - 1
        endif

        let s:level =  s:level + 1
        let beforeelse = FindTheIfOfAnElse(beforeelse, a:StopAfterFirstPrevElse)
    endif

    return beforeelse

endfunction " }}}

let s:defaultORcase = '^\s*\%(default\|case\).*:'

function! FindTheSwitchIndent (lnum) " {{{
    " Yes that's right, another very clever recursive function by the
    " author of the famous FindTheIfOfAnElse()


    let test = GetLastRealCodeLNum(a:lnum - 1)

    if test <= 1
        return indent(1) - &sw * b:PHP_vintage_case_default_indent
    end

    " A closing bracket? let skip the whole block to save some recursive calls
    if getline(test) =~ '^\s*}'
        let test = FindOpenBracket(test)

        " Put us on the line above the block starter since if it's a switch,
        " it's not the one we want.
        if getline(test) =~ '^\s*{'
            let test = GetLastRealCodeLNum(GetLastRealCodeLNum(test - 1) - 1)
        endif
    endif

    " did we find it?
    if getline(test) =~# '^\s*switch\>'
        return indent(test)
    elseif getline(test) =~# s:defaultORcase
        return indent(test) - &sw * b:PHP_vintage_case_default_indent
    else
        return FindTheSwitchIndent(test)
    endif

endfunction "}}}


function! IslinePHP (lnum, tofind) " {{{
    " This function asks to the syntax if the pattern 'tofind' on the line
    " number 'lnum' is PHP code (very slow...).
    let cline = getline(a:lnum)

    if a:tofind==""
        " This correct the issue where lines beginning by a
        " single or double quote were not indented in some cases.
        let tofind = "^\\s*[\"']*\\s*\\zs\\S"
    else
        let tofind = a:tofind
    endif

    " ignore case
    let tofind = tofind . '\c'

    "find the first non blank char in the current line
    let coltotest = match (cline, tofind) + 1

    " ask to syntax what is its name
    let synname = synIDattr(synID(a:lnum, coltotest, 0), "name")

"       echom synname
    " if matchstr(synname, '^...') == "php" || synname=="Delimiter" || synname =~? '^javaScript'
    if synname =~ '^php' || synname=="Delimiter" || synname =~? '^javaScript'
        return synname
    else
        return ""
    endif
endfunction " }}}

let s:notPhpHereDoc = '\%(break\|return\|continue\|exit\|die\|else\)'
"BD808 WUZ HERE!
let s:blockstart = '\%(\%(\%(}\s*\)\=else\%(\s\+\)\=\)\=if\>\|else\>\|while\>\|switch\>\|for\%(each\)\=\>\|declare\>\|class\>\|interface\>\|abstract\>\|try\>\|catch\>\)'

" make sure the options needed for this script to work correctly are set here
" for the last time. They could have been overridden by any 'onevent'
" associated setting file...
let s:autoresetoptions = 0
if ! s:autoresetoptions
    "au BufWinEnter,Syntax      *.php,*.php\d,*.phtml,*.ctp,*.inc       call ResetPhpOptions()
    let s:autoresetoptions = 1
endif

function! ResetPhpOptions()
    if ! b:optionsset && &filetype == "php"
        if b:PHP_autoformatcomment

            " Set the comment setting to something correct for PHP
            setlocal comments=s1:/*,mb:*,ex:*/,://,:#

            " disable Auto-wrap of text
            setlocal formatoptions-=t
            " Allow formatting of comments with "gq"
            setlocal formatoptions+=q
            " Insert comment leader after hitting <Enter>
            setlocal formatoptions+=r
            " Insert comment leader after hitting o or O in normal mode
            setlocal formatoptions+=o
            " Uses trailing white spaces to detect paragraphs
            setlocal formatoptions+=w
            " Autowrap comments using textwidth
            setlocal formatoptions+=c
            " Do not wrap if you modify a line after textwidth
            setlocal formatoptions+=b
        endif
        let b:optionsset = 1
    endif
endfunc

call ResetPhpOptions()

function! GetPhpIndent()
    "##############################################
    "########### MAIN INDENT FUNCTION #############
    "##############################################

    " variable added on 2005-01-15 to make <script> tags really indent correctly (not pretty at all :-/ )
    let b:GetLastRealCodeLNum_ADD = 0

    " This detect if the user is currently typing text between each call
    let UserIsEditing=0
    if  b:PHP_oldchangetick != b:changedtick
        let b:PHP_oldchangetick = b:changedtick
        let UserIsEditing=1
    endif

    if b:PHP_default_indenting
        let b:PHP_default_indenting = g:PHP_default_indenting * &sw
    endif

    " current line
    let cline = getline(v:lnum)

    " Let's detect if we are indenting just one line or more than 3 lines
    " in the last case we can slightly optimize our algorithm (by trusting
    " what is above the current line)
    if !b:PHP_indentinghuge && b:PHP_lastindented > b:PHP_indentbeforelast
        if b:PHP_indentbeforelast
            let b:PHP_indentinghuge = 1
            " echom 'Large indenting detected, speed optimizations engaged (v1.34)'
        endif
        let b:PHP_indentbeforelast = b:PHP_lastindented
    endif

    " If the line we are indenting isn't directly under the previous non-blank
    " line of the file then deactivate the optimization procedures and reset
    " status variable (we restart from scratch)
    if b:InPHPcode_checked && prevnonblank(v:lnum - 1) != b:PHP_lastindented
        if b:PHP_indentinghuge
            " echom 'Large indenting deactivated'
            let b:PHP_indentinghuge = 0
            let b:PHP_CurrentIndentLevel = b:PHP_default_indenting
        endif
        let b:PHP_lastindented = v:lnum
        let b:PHP_LastIndentedWasComment=0
        let b:PHP_InsideMultilineComment=0
        let b:PHP_indentbeforelast = 0

        let b:InPHPcode = 0
        let b:InPHPcode_checked = 0
        let b:InPHPcode_and_script = 0
        let b:InPHPcode_tofind = ""

    elseif v:lnum > b:PHP_lastindented
        " we are indenting line in > order (we can rely on the line before)
        let real_PHP_lastindented = b:PHP_lastindented
        let b:PHP_lastindented = v:lnum
    endif

    " We must detect if we are in PHPCODE or not, but one time only, then
    " we will detect php end and start tags, comments /**/ and HereDoc
    " tags
    if !b:InPHPcode_checked " {{{ One time check
        let b:InPHPcode_checked = 1

        let synname = ""
        if cline !~ '<?.*?>'
            " the line could be blank (if the user presses 'return' so we use
            " prevnonblank()) We ask to Syntax
            let synname = IslinePHP (prevnonblank(v:lnum), "")
        endif

        if synname!=""
            if synname != "phpHereDoc" && synname != "phpHereDocDelimiter"
                let b:InPHPcode = 1
                let b:InPHPcode_tofind = ""

                if synname =~# "^phpComment"
                    let b:UserIsTypingComment = 1
                else
                    let b:UserIsTypingComment = 0
                endif

                if synname =~? '^javaScript'
                    let b:InPHPcode_and_script = 1
                endif

            else
                "We are inside an "HereDoc"
                let b:InPHPcode = 0
                let b:UserIsTypingComment = 0

                let lnum = v:lnum - 1
                while getline(lnum) !~? '<<<''\=\a\w*''\=$' && lnum > 1
                    let lnum = lnum - 1
                endwhile

                let b:InPHPcode_tofind = substitute( getline(lnum), '^.*<<<''\=\(\a\w*\)''\=$', '^\\s*\1;\\=$', '')
            endif
        else
            " IslinePHP returned "" => we are not in PHP or Javascript
            let b:InPHPcode = 0
            let b:UserIsTypingComment = 0
            " Then we have to find a php start tag...
            let b:InPHPcode_tofind = '<?\%(.*?>\)\@!\|<script.*>'
        endif
    endif "!b:InPHPcode_checked }}}

    " Now we know where we are so we can verify the line right above the
    " current one to see if we have to stop or restart php indenting

    " Test if we are indenting PHP code {{{
    " Find an executable php code line above the current line.
    let lnum = prevnonblank(v:lnum - 1)
    let last_line = getline(lnum)

    " If we aren't in php code, then there is something we have to find
    if b:InPHPcode_tofind!=""
        if cline =~? b:InPHPcode_tofind
            let b:InPHPcode = 1
            let b:InPHPcode_tofind = ""
            let b:UserIsTypingComment = 0
            if cline =~ '\*/'
                " End comment tags must be indented like start comment tags
                call cursor(v:lnum, 1)
                if cline !~ '^\*/'
                    call search('\*/', 'W')
                endif
                " find the most outside /*
                let lnum = searchpair('/\*', '', '\*/', s:searchpairflags, 'Skippmatch2()')

                let b:PHP_CurrentIndentLevel = b:PHP_default_indenting

                " prevent a problem if multiline /**/ comment are surrounded by
                " other types of comments
                let b:PHP_LastIndentedWasComment = 0

                if cline =~ '^\s*\*/'
                    return indent(lnum) + 1
                else
                    return indent(lnum)
                endif

            elseif cline =~? '<script\>'
                " a more accurate test is useless since there isn't any other possibility
                let b:InPHPcode_and_script = 1
                " this will make GetLastRealCodeLNum to add one line to its
                " given argument so it can detect the <script> easily (that is
                " simpler/quicker than using a regex...)
                let b:GetLastRealCodeLNum_ADD = v:lnum
            endif
        endif
    endif

    " ### If we are in PHP code, we test the line before to see if we have to
    " stop indenting
    if b:InPHPcode

        " Was last line containing a PHP end tag ?
        if !b:InPHPcode_and_script && last_line =~ '\%(<?.*\)\@<!?>\%(.*<?\)\@!' && IslinePHP(lnum, '?>')=~"Delimiter"
            if cline !~? s:PHP_startindenttag
                let b:InPHPcode = 0
                let b:InPHPcode_tofind = s:PHP_startindenttag
            elseif cline =~? '<script\>'
                let b:InPHPcode_and_script = 1
            endif

        " Was last line the start of a HereDoc ?
        elseif last_line =~? '<<<''\=\a\w*''\=$'
            let b:InPHPcode = 0
            let b:InPHPcode_tofind = substitute( last_line, '^.*<<<''\=\(\a\w*\)''\=$', '^\\s*\1;\\=$', '')

        " Skip /* \n+ */ comments except when the user is currently
        " writing them or when it is a comment (ie: not a code put in comment)
        elseif !UserIsEditing && cline =~ '^\s*/\*\%(.*\*/\)\@!' && getline(v:lnum + 1) !~ '^\s*\*'
            let b:InPHPcode = 0
            let b:InPHPcode_tofind = '\*/'

        " is current line the end of a HTML script ? (we indent scripts the
        " same as php code)
        elseif cline =~? '^\s*</script>'
            let b:InPHPcode = 0
            let b:InPHPcode_tofind = s:PHP_startindenttag
            " Note that b:InPHPcode_and_script is still true so that the
            " </script> can be indented correctly
        endif
    endif " }}}


    " Non PHP code is let as it is
    if !b:InPHPcode && !b:InPHPcode_and_script
        return -1
    endif

    " Align correctly multi // or # lines
    " Indent successive // or # comment the same way the first is {{{
    let addSpecial = 0
    if cline =~ '^\s*\%(//\|#\|/\*.*\*/\s*$\)'
        let addSpecial = b:PHP_outdentSLComments
        if b:PHP_LastIndentedWasComment == 1
            return indent(real_PHP_lastindented)
        endif
        let b:PHP_LastIndentedWasComment = 1
    else
        let b:PHP_LastIndentedWasComment = 0
    endif " }}}

    " Indent multiline /* comments correctly {{{

    "if we are on the start of a MULTI * beginning comment or if the user is
    "currently typing a /* beginning comment.
    if b:PHP_InsideMultilineComment || b:UserIsTypingComment
        if cline =~ '^\s*\*\%(\/\)\@!'
            " if cline == '*'
            if last_line =~ '^\s*/\*'
                " if last_line == '/*'
                return indent(lnum) + 1
            else
                return indent(lnum)
            endif
        else
            let b:PHP_InsideMultilineComment = 0
        endif
    endif

    if !b:PHP_InsideMultilineComment && cline =~ '^\s*/\*' && cline !~ '\*/\s*$'
        " if cline == '/*' and doesn't end with '*/'
        if getline(v:lnum + 1) !~ '^\s*\*'
            "BD808 WUZ HERE!
            " match indent to previous php line
            return indent(b:PHP_lastindented)
        endif
        let b:PHP_InsideMultilineComment = 1
    endif " }}}

    " Some tags are always indented to col 1

    " Things always indented at col 1 (PHP delimiter: <?, ?>, Heredoc end) {{{
    " PHP start tags are always at col 1, useless to indent unless the end tag
    " is on the same line
    if cline =~# '^\s*<?' && cline !~ '?>' && b:PHP_outdentphpescape
        return 0
    endif

    " PHP end tags are always at col 1, useless to indent unless if it's
    " followed by a start tag on the same line
    if  cline =~ '^\s*?>' && cline !~# '<?' && b:PHP_outdentphpescape
        return 0
    endif

    " put HereDoc end tags at start of lines
    if cline =~? '^\s*\a\w*;$\|^\a\w*$' && cline !~? s:notPhpHereDoc
        return 0
    endif " }}}

    let s:level = 0

    " Find an executable php code line above the current line.
    let lnum = GetLastRealCodeLNum(v:lnum - 1)

    " last line
    let last_line = getline(lnum)
    " by default
    let ind = indent(lnum)
    let endline= s:endline

    if ind==0 && b:PHP_default_indenting
        let ind = b:PHP_default_indenting
    endif

    " Hit the start of the file, use default indent.
    if lnum == 0
        return b:PHP_default_indenting + addSpecial
    endif

    " Search the matching open bracket (with searchpair()) and set the indent
    " of line to the indent of the matching line. (unless it's a vim folding
    " end tag)
    if cline =~ '^\s*}\%(}}\)\@!'
        "BD808 WUZ HERE!
        let olnum = FindOpenBracket(v:lnum)
        let oline = getline(olnum)
        " check to see if opening line for this block was a hanging indent
        " from a long argument list
        if oline =~ '\S\+\s*)\s*{'.endline
            call cursor(olnum, 1)
            call search(')\s*{'.endline, 'W')
            let openedparent = searchpair('(', '', ')', 'bW', 'Skippmatch()')
            if openedparent != olnum
                " take indent from parent line
                let ind = indent(openedparent)
            else
                " take indent from open bracket line
                let ind = indent(olnum)
            endif
        else
            " parent is not a function decl, take indent from open brace line
            let ind = indent(olnum)
        endif
        " return to default indent level
        let b:PHP_CurrentIndentLevel = b:PHP_default_indenting
        return ind
    endif

    " Check for end of comment and indent it like its beginning
    if cline =~ '^\s*\*/'
        " End comment tags must be indented like start comment tags
        call cursor(v:lnum, 1)
        if cline !~ '^\*/'
            call search('\*/', 'W')
        endif
        " find the most outside /*
        let lnum = searchpair('/\*', '', '\*/', s:searchpairflags, 'Skippmatch2()')

        let b:PHP_CurrentIndentLevel = b:PHP_default_indenting

        if cline =~ '^\s*\*/'
            return indent(lnum) + 1
        else
            return indent(lnum)
        endif
    endif


    " if the last line is a stated line and it's not indented then why should
    " we indent this one??
    " Do not do this if the last line is a ')' because array indentation can
    " fail... and defaultORcase can be at col 0.
    " if optimized mode is active and nor current or previous line are an 'else'
    " or the end of a possible bracketless thing then indent the same as the previous
    " line
    if last_line =~ '[;}]'.endline && last_line !~ '^)' && last_line !~# s:defaultORcase " Added && last_line !~ '^)' on 2007-12-30
        if ind==b:PHP_default_indenting
            " if no indentation for the previous line
            return b:PHP_default_indenting + addSpecial
        elseif b:PHP_indentinghuge && ind==b:PHP_CurrentIndentLevel && cline !~# '^\s*\%(else\|\%(case\|default\).*:\|[})];\=\)' && last_line !~# '^\s*\%(\%(}\s*\)\=else\)' && getline(GetLastRealCodeLNum(lnum - 1))=~';'.endline
            return b:PHP_CurrentIndentLevel + addSpecial
        endif
    endif

    " used to prevent redundant tests in the last part of the script
    let LastLineClosed = 0

    let terminated = '\%(;\%(\s*?>\)\=\|<<<''\=\a\w*''\=$\|^\s*}\)'.endline
    " What is a terminated line?
    " - a line terminated by a ";" optionally followed by a "?>"
    " - a HEREDOC starter line (the content of such block is never seen by this script)
    " - a "}" not followed by a "{"

    let unstated   = '\%(^\s*'.s:blockstart.'.*)\|\%(//.*\)\@<!\<e'.'lse\>\)'.endline
    " What is an unstated line?
    " - an "else" at the end of line
    " - a  s:blockstart (if while etc...) followed by anything but a ";" at
    "   the end of line

    " if the current line is an 'else' starting line
    " (to match an 'else' preceded by a '}' is irrelevant and futile - see
    " code above)
    if ind != b:PHP_default_indenting && cline =~# '^\s*else\%(if\)\=\>'
        " prevent optimized to work at next call  XXX why ?
        let b:PHP_CurrentIndentLevel = b:PHP_default_indenting
        return indent(FindTheIfOfAnElse(v:lnum, 1))
    elseif cline =~# s:defaultORcase
        " case and default need a special treatment
        return FindTheSwitchIndent(v:lnum) + &sw * b:PHP_vintage_case_default_indent
    elseif cline =~ '^\s*)\=\s*{'
        let previous_line = last_line
        let last_line_num = lnum

        " let's find the indent of the block starter (if, while, for, etc...)
        while last_line_num > 1

            if previous_line =~ '^\s*\%(' . s:blockstart . '\|\%([a-zA-Z]\s*\)*function\)'

                let ind = indent(last_line_num)

                " If the PHP_BracesAtCodeLevel is set then indent the '{'
                if  b:PHP_BracesAtCodeLevel
                    let ind = ind + &sw
                endif

                return ind
            endif

            let last_line_num = last_line_num - 1
            let previous_line = getline(last_line_num)
        endwhile

    elseif last_line =~# unstated && cline !~ '^\s*);\='.endline
        let ind = ind + &sw " we indent one level further when the preceding line is not stated
        "echo "42"
        "call getchar()
        return ind + addSpecial

        " If the last line is terminated by ';' or if it's a closing '}'
        " We need to check if this isn't the end of a multilevel non '{}'
        " structure such as:
        " Exemple:
        "                       if ($truc)
        "                               echo 'truc';
        "
        "       OR
        "
        "                       if ($truc)
        "                               while ($truc) {
        "                                       lkhlkh();
        "                                       echo 'infinite loop\n';
        "                               }
        "
        "       OR even (ADDED for version 1.17 - no modification required )
        "
        "                       $thing =
        "                               "something";
    elseif (ind != b:PHP_default_indenting || last_line =~ '^)' ) && last_line =~ terminated " Added || last_line =~ '^)' on 2007-12-30 (array indenting problem broke other things)
        " If we are here it means that the previous line is:
        " - a *;$ line
        " - a [beginning-blanck] } followed by anything but a { $
        let previous_line = last_line
        let last_line_num = lnum
        let LastLineClosed = 1
        " The idea here is to check if the current line is after a non '{}'
        " structure so we can indent it like the top of that structure.
        " The top of that structure is characterized by a if (ff)$ style line
        " preceded by a stated line. If there is no such structure then we
        " just have to find two 'normal' lines following each other with the
        " same indentation and with the first of these two lines terminated by
        " a ; or by a }...

        while 1
            " let's skip '{}' blocks
            if previous_line =~ '^\s*}'
                " find the opening '{'
                let last_line_num = FindOpenBracket(last_line_num)

                " if the '{' is alone on the line get the line before
                if getline(last_line_num) =~ '^\s*{'
                    let last_line_num = GetLastRealCodeLNum(last_line_num - 1)
                endif

                let previous_line = getline(last_line_num)

                continue
            else
                " At this point we know that the previous_line isn't a closing
                " '}' so we can check if we really are in such a structure.

                " it's not a '}' but it could be an else alone...
                if getline(last_line_num) =~# '^\s*else\%(if\)\=\>'
                    let last_line_num = FindTheIfOfAnElse(last_line_num, 0)
                    " re-run the loop (we could find a '}' again)
                    continue
                endif

                " So now it's ok we can check :-)
                " A good quality is to have confidence in oneself so to know
                " if yes or no we are in that struct lets test the indent of
                " last_line_num and of last_line_num - 1!
                " If those are == then we are almost done.
                "
                " That isn't sufficient, we need to test how the first of
                " these 2 lines ends...

                " Remember the 'topest' line we found so far
                let last_match = last_line_num

                let one_ahead_indent = indent(last_line_num)
                let last_line_num = GetLastRealCodeLNum(last_line_num - 1)
                let two_ahead_indent = indent(last_line_num)
                let after_previous_line = previous_line
                let previous_line = getline(last_line_num)


                " If we find a '{' or a case/default then we are inside that block so lets
                " indent properly... Like the line following that block starter
                if previous_line =~# s:defaultORcase.'\|{'.endline
                    break
                endif

                " The 3 lines below are not necessary for the script to work
                " but it makes it work a little more faster in some (rare) cases.
                " We verify if we are at the top of a non '{}' struct.
                if after_previous_line=~# '^\s*'.s:blockstart.'.*)'.endline && previous_line =~# '[;}]'.endline
                    break
                endif

                if one_ahead_indent == two_ahead_indent || last_line_num < 1
                    " So the previous line and the line before are at the same
                    " col. Now we just have to check if the line before is a ;$ or [}]$ ended line
                    " we always check the most ahead line of the 2 lines so
                    " it's useless to match ')$' since the lines couldn't have
                    " the same indent...
                    if previous_line =~# '\%(;\|^\s*}\)'.endline || last_line_num < 1
                        break
                    endif
                endif
            endif
        endwhile

        if indent(last_match) != ind
            " let's use the indent of the last line matched by the algorithm above
            let ind = indent(last_match)
            " line added in version 1.02 to prevent optimized mode
            " from acting in some special cases
            let b:PHP_CurrentIndentLevel = b:PHP_default_indenting

            return ind + addSpecial
        endif
        " if nothing was done lets the old script continue
    endif

    let plinnum = GetLastRealCodeLNum(lnum - 1)
    " previous to last line
    let AntepenultimateLine = getline(plinnum)

    " REMOVE comments at end of line before treatment
    " the first part of the regex removes // from the end of line when they are
    " followed by a number of '"' which is a multiple of 2. The second part
    " removes // that are not followed by any '"'
    " Sorry for this unreadable thing...
    let last_line = substitute(last_line,"\\(//\\|#\\)\\(\\(\\([^\"']*\\([\"']\\)[^\"']*\\5\\)\\+[^\"']*$\\)\\|\\([^\"']*$\\)\\)",'','')


    if ind == b:PHP_default_indenting
        if last_line =~ terminated
            let LastLineClosed = 1
        endif
    endif

    " Indent blocks enclosed by {} or () (default indenting)
    if !LastLineClosed
        "echo "start"
        "call getchar()

        " the last line isn't a .*; or a }$ line
        " Indent correctly multilevel and multiline '(.*)' things

        " if the last line is a [{(]$ or a multiline function call (or array
        " declaration) with already one parameter on the opening ( line
        if last_line =~# '[{(]'.endline || last_line =~? '\h\w*\s*(.*,$' && AntepenultimateLine !~ '[,(]'.endline

            if !b:PHP_BracesAtCodeLevel || last_line !~# '^\s*{'
                let ind = ind + &sw
            endif

            "BD808 WUZ HERE!
            " if last_line !~ '^.*{'
            if last_line !~ '^.*{'.endline
                " last line wasn't a block open, double the indent for the
                " current line
                let ind = ind + &sw
            endif

            "    echo "43"
            "    call getchar()
            if b:PHP_BracesAtCodeLevel || b:PHP_vintage_case_default_indent == 1
                " case and default are not indented inside blocks
                let b:PHP_CurrentIndentLevel = ind

                return ind + addSpecial
            endif

        " If the last line isn't empty and ends with a '),' then check if the
        " ')' was opened on the same line, if not it means it closes a
        " multiline '(.*)' thing and that the current line need to be
        " de-indented one time.
        elseif last_line =~ '\S\+\s*),'.endline
            call cursor(lnum, 1)
            call search('),'.endline, 'W')
            let openedparent = searchpair('(', '', ')', 'bW', 'Skippmatch()')
            if openedparent != lnum
                let ind = indent(openedparent)
            endif

        " if the line before starts a block then we need to indent the
        " current line.
        elseif last_line =~ '^\s*'.s:blockstart
            "BD808 WUZ HERE!
            if last_line =~ '\S\+\s*)\s*{'.endline
                call cursor(lnum, 1)
                call search(')\s*{'.endline, 'W')
                let openedparent = searchpair('(', '', ')', 'bW', 'Skippmatch()')
                if openedparent != lnum
                    let ind = indent(openedparent)
                endif
            endif
            "end BD808 WUZ HERE!
            let ind = ind + &sw

            "echo cline. "  --test 5--   " . ind
            "call getchar()

        " In all other cases if the last line isn't terminated indent 1
        " level higher but only if the last line wasn't already indented
        " for the same "code event"/reason. IE: if the antepenultimate line is
        " terminated.
        "
        " 2nd explanation:
        "       - Test if the antepenultimate line is terminated or is
        "       a default/case if yes indent else let since it must have
        "       been indented correctly already

        "elseif cline !~ '^\s*{' && AntepenultimateLine =~ '\%(;\%(\s*?>\)\=\|<<<\a\w*\|{\|^\s*'.s:blockstart.'.*)\)'.endline.'\|^\s*}\|'.s:defaultORcase
        elseif AntepenultimateLine =~ '\%(;\%(\s*?>\)\=\|<<<''\=\a\w*''\=$\|^\s*}\|{\)'.endline . '\|' . s:defaultORcase
            "BD808 WUZ HERE!
            let ind = ind + b:PHP_continuation_indenting
            "echo pline. "  --test 2--   " . ind
            "call getchar()
        endif

    endif

    "echo "end"
    "call getchar()
    " If the current line closes a multiline function call or array def
    if cline =~  '^\s*);\='
        let ind = ind - &sw
    endif

    let b:PHP_CurrentIndentLevel = ind
    return ind + addSpecial
endfunction

"BD808 WUZ HERE!
" Description:  html indenter
" Author:       Johannes Zellner <johannes@zellner.org>
" Last Change:  Mo, 05 Jun 2006 22:32:41 CEST
if exists('g:html_indent_tags')
    unlet g:html_indent_tags
endif

" [-- helper function to assemble tag list --]
fun! <SID>HtmlIndentPush(tag)
    if exists('g:html_indent_tags')
        let g:html_indent_tags = g:html_indent_tags.'\|'.a:tag
    else
        let g:html_indent_tags = a:tag
    endif
endfun


" [-- <ELEMENT ? - - ...> --]
call <SID>HtmlIndentPush('a')
call <SID>HtmlIndentPush('abbr')
call <SID>HtmlIndentPush('acronym')
call <SID>HtmlIndentPush('address')
call <SID>HtmlIndentPush('b')
call <SID>HtmlIndentPush('bdo')
call <SID>HtmlIndentPush('big')
call <SID>HtmlIndentPush('blockquote')
call <SID>HtmlIndentPush('button')
call <SID>HtmlIndentPush('caption')
call <SID>HtmlIndentPush('center')
call <SID>HtmlIndentPush('cite')
call <SID>HtmlIndentPush('code')
call <SID>HtmlIndentPush('colgroup')
call <SID>HtmlIndentPush('del')
call <SID>HtmlIndentPush('dfn')
call <SID>HtmlIndentPush('dir')
call <SID>HtmlIndentPush('div')
call <SID>HtmlIndentPush('dl')
call <SID>HtmlIndentPush('em')
call <SID>HtmlIndentPush('fieldset')
call <SID>HtmlIndentPush('font')
call <SID>HtmlIndentPush('form')
call <SID>HtmlIndentPush('frameset')
call <SID>HtmlIndentPush('h1')
call <SID>HtmlIndentPush('h2')
call <SID>HtmlIndentPush('h3')
call <SID>HtmlIndentPush('h4')
call <SID>HtmlIndentPush('h5')
call <SID>HtmlIndentPush('h6')
call <SID>HtmlIndentPush('i')
call <SID>HtmlIndentPush('iframe')
call <SID>HtmlIndentPush('ins')
call <SID>HtmlIndentPush('kbd')
call <SID>HtmlIndentPush('label')
call <SID>HtmlIndentPush('legend')
call <SID>HtmlIndentPush('map')
call <SID>HtmlIndentPush('menu')
call <SID>HtmlIndentPush('noframes')
call <SID>HtmlIndentPush('noscript')
call <SID>HtmlIndentPush('object')
call <SID>HtmlIndentPush('ol')
call <SID>HtmlIndentPush('optgroup')
" call <SID>HtmlIndentPush('pre')
call <SID>HtmlIndentPush('q')
call <SID>HtmlIndentPush('s')
call <SID>HtmlIndentPush('samp')
call <SID>HtmlIndentPush('script')
call <SID>HtmlIndentPush('select')
call <SID>HtmlIndentPush('small')
call <SID>HtmlIndentPush('span')
call <SID>HtmlIndentPush('strong')
call <SID>HtmlIndentPush('style')
call <SID>HtmlIndentPush('sub')
call <SID>HtmlIndentPush('sup')
call <SID>HtmlIndentPush('table')
call <SID>HtmlIndentPush('textarea')
call <SID>HtmlIndentPush('title')
call <SID>HtmlIndentPush('tt')
call <SID>HtmlIndentPush('u')
call <SID>HtmlIndentPush('ul')
call <SID>HtmlIndentPush('var')


" [-- <ELEMENT ? O O ...> --]
if !exists('g:html_indent_strict')
    call <SID>HtmlIndentPush('body')
    call <SID>HtmlIndentPush('head')
    call <SID>HtmlIndentPush('html')
    call <SID>HtmlIndentPush('tbody')
endif


" [-- <ELEMENT ? O - ...> --]
if !exists('g:html_indent_strict_table')
    call <SID>HtmlIndentPush('th')
    call <SID>HtmlIndentPush('td')
    call <SID>HtmlIndentPush('tr')
    call <SID>HtmlIndentPush('tfoot')
    call <SID>HtmlIndentPush('thead')
endif

delfun <SID>HtmlIndentPush

let s:cpo_save = &cpo
set cpo-=C

" [-- count indent-increasing tags of line a:lnum --]
fun! <SID>HtmlIndentOpen(lnum, pattern)
    let s = substitute('x'.getline(a:lnum),
    \ '.\{-}\(\(<\)\('.a:pattern.'\)\>\)', "\1", 'g')
    let s = substitute(s, "[^\1].*$", '', '')
    return strlen(s)
endfun

" [-- count indent-decreasing tags of line a:lnum --]
fun! <SID>HtmlIndentClose(lnum, pattern)
    let s = substitute('x'.getline(a:lnum),
    \ '.\{-}\(\(<\)/\('.a:pattern.'\)\>>\)', "\1", 'g')
    let s = substitute(s, "[^\1].*$", '', '')
    return strlen(s)
endfun

" [-- count indent-increasing '{' of (java|css) line a:lnum --]
fun! <SID>HtmlIndentOpenAlt(lnum)
    return strlen(substitute(getline(a:lnum), '[^{]\+', '', 'g'))
endfun

" [-- count indent-decreasing '}' of (java|css) line a:lnum --]
fun! <SID>HtmlIndentCloseAlt(lnum)
    return strlen(substitute(getline(a:lnum), '[^}]\+', '', 'g'))
endfun

" [-- return the sum of indents respecting the syntax of a:lnum --]
fun! <SID>HtmlIndentSum(lnum, style)
    if a:style == match(getline(a:lnum), '^\s*</')
        if a:style == match(getline(a:lnum), '^\s*</\<\('.g:html_indent_tags.'\)\>')
            let open = <SID>HtmlIndentOpen(a:lnum, g:html_indent_tags)
            let close = <SID>HtmlIndentClose(a:lnum, g:html_indent_tags)
            if 0 != open || 0 != close
                return open - close
            endif
        endif
    endif
    if '' != &syntax &&
        \ synIDattr(synID(a:lnum, 1, 1), 'name') =~ '\(css\|java\).*' &&
        \ synIDattr(synID(a:lnum, strlen(getline(a:lnum)), 1), 'name')
        \ =~ '\(css\|java\).*'
        if a:style == match(getline(a:lnum), '^\s*}')
            return <SID>HtmlIndentOpenAlt(a:lnum) - <SID>HtmlIndentCloseAlt(a:lnum)
        endif
    endif
    return 0
endfun

fun! HtmlIndentGet(lnum)
    " Find a non-empty line above the current line.
    let lnum = prevnonblank(a:lnum - 1)

    " Hit the start of the file, use zero indent.
    if lnum == 0
        return 0
    endif

    let restore_ic = &ic
    setlocal ic " ignore case

    " [-- special handling for <pre>: no indenting --]
    if getline(a:lnum) =~ '\c</pre>'
                \ || 0 < searchpair('\c<pre>', '', '\c</pre>', 'nWb')
                \ || 0 < searchpair('\c<pre>', '', '\c</pre>', 'nW')
        " we're in a line with </pre> or inside <pre> ... </pre>
        if restore_ic == 0
          setlocal noic
        endif
        return -1
    endif

    " [-- special handling for <javascript>: use cindent --]
    let js = '<script.*type\s*=\s*.*java'

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " by Tye Zdrojewski <zdro@yahoo.com>, 05 Jun 2006
    " ZDR: This needs to be an AND (we are 'after the start of the pair' AND
    "      we are 'before the end of the pair').  Otherwise, indentation
    "      before the start of the script block will be affected; the end of
    "      the pair will still match if we are before the beginning of the
    "      pair.
    "
    if   0 < searchpair(js, '', '</script>', 'nWb')
    \ && 0 < searchpair(js, '', '</script>', 'nW')
        " we're inside javascript
        if getline(lnum) !~ js && getline(a:lnum) != '</script>'
            if restore_ic == 0
              setlocal noic
            endif
            return cindent(a:lnum)
        endif
    endif

    if getline(lnum) =~ '\c</pre>'
        " line before the current line a:lnum contains
        " a closing </pre>. --> search for line before
        " starting <pre> to restore the indent.
        let preline = prevnonblank(search('\c<pre>', 'bW') - 1)
        if preline > 0
            if restore_ic == 0
              setlocal noic
            endif
            return indent(preline)
        endif
    endif

    let ind = <SID>HtmlIndentSum(lnum, -1)
    let ind = ind + <SID>HtmlIndentSum(a:lnum, 0)

    if restore_ic == 0
        setlocal noic
    endif

    return indent(lnum) + (&sw * ind)
endfun

" ==========================================================================
" fancy combined indenting function
function! GetPhpHtmlIndent(lnum)
  let php_ind = GetPhpIndent()
  "echom "php ind:" php_ind
  " priority one for php indent script
  if php_ind > -1
    return php_ind
  endif

  let html_ind = HtmlIndentGet(a:lnum)
  "echom "html ind:" html_ind
  if html_ind > -1
    return html_ind
  endif
  return -1
endfunction

" vim: set ts=8 sw=4 sts=4:
