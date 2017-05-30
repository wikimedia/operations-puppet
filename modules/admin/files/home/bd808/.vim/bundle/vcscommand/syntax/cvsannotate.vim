" Vim syntax file
" Language:	CVS annotate output
" Maintainer:	Bob Hiestand <bob.hiestand@gmail.com>
" Remark:	Used by the cvscommand plugin.  Originally written by Mathieu
" Clabaut
" License:
" Copyright (c) Bob Hiestand
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
" IN THE SOFTWARE.

if version < 600
	syntax clear
elseif exists("b:current_syntax")
	finish
endif

syn match cvsDate 	/\d\d-...-\d\d/ 		contained
syn match cvsName  	/(\S* /hs=s+1,he=e-1 		contained nextgroup=cvsDate
syn match cvsVer 	/^\d\+\(\.\d\+\)\+/ 		contained nextgroup=cvsName
syn region cvsHead 	start="^\d\+\.\d\+" end="):" 	contains=cvsVer,cvsName,cvsDate

if !exists("did_cvsannotate_syntax_inits")
	let did_cvsannotate_syntax_inits = 1
	hi link cvsDate 	Comment
	hi link cvsName	Type
	hi link cvsVer	Statement
endif

let b:current_syntax="CVSAnnotate"
