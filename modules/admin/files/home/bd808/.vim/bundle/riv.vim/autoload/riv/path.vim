"=============================================
"    Name: path.vim
"    File: path.vim
" Summary: calc the path of files
"  Author: Rykka G.F
"  Update: 2012-07-07
"=============================================
let s:cpo_save = &cpo
set cpo-=C

let s:slash = has('win32') || has('win64') ? '\' : '/'
let s:win =  has('win32') || has('win64') ? 1 : 0

let s:c = g:_riv_c
fun! riv#path#root(...) "{{{
    return g:_riv_c.p[a:0 ? a:1 : riv#id()]._root_path
endfun "}}}

fun! riv#path#build_ft(ft,...) "{{{
    return g:_riv_c.p[a:0 ? a:1 : riv#id()]._build_path . a:ft . s:slash
endfun "}}}
fun! riv#path#p_build(...) "{{{
    " >>> echo riv#path#p_build()
    " _build
    return g:_riv_c.p[a:0 ? a:1 : riv#id()].build_path
endfun "}}}
fun! riv#path#build_path(...) "{{{
    return g:_riv_c.p[a:0 ? a:1 : riv#id()]._build_path
endfun "}}}
fun! riv#path#scratch_path(...) "{{{
    return g:_riv_c.p[a:0 ? a:1 : riv#id()]._scratch_path
endfun "}}}
fun! riv#path#file_link_style(...) "{{{
    return g:_riv_c.p[a:0 ? a:1 : riv#id()].file_link_style
endfun "}}}

fun! riv#path#ext(...) "{{{
    " file suffix 
    " >>> echo riv#path#ext()
    " .rst
    return g:_riv_c.p[a:0 ? a:1 : riv#id()].source_suffix
endfun "}}}
fun! riv#path#idx(...) "{{{
    " project master doc.
    " >>> echo riv#path#idx()
    " index
    return g:_riv_c.p[a:0 ? a:1 : riv#id()].master_doc
endfun "}}}
fun! riv#path#idx_file(...) "{{{
    " >>> echo riv#path#idx_file()
    " index.rst
    return call('riv#path#idx',a:000) . call('riv#path#ext',a:000)  
endfun "}}}

fun! riv#path#p_ext(...) "{{{
    return g:_riv_c.p[a:0 ? a:1 : riv#id()]._source_suffix
endfun "}}}

fun! riv#path#is_ext(file) "{{{
    " >>> echo riv#path#is_ext('aaa.rst')
    " 1
    " >>> echo riv#path#is_ext('aa.arst')
    " 0
    return fnamemodify(a:file,':e') == riv#path#p_ext()
endfun "}}}

fun! riv#path#directory(path) "{{{
    return riv#path#is_directory(a:path) ? a:path : a:path . s:slash
endfun "}}}
fun! riv#path#rel_to(dir, path) "{{{
    " return the related path to 'dir', default is current file's dir
    
    let dir = riv#path#is_directory(a:dir) ? a:dir : fnamemodify(a:dir,':h') . '/'
    let dir = fnamemodify(dir, ':gs?\?/?') 
    let path = fnamemodify(a:path, ':gs?\?/?') 
    if match(path, dir) == -1
        let p = riv#path#is_directory(path) ? path : fnamemodify(path,':h') . '/'
        let tail = fnamemodify(path,':t')
        if match(dir, p) == -1
            throw g:_riv_e.NOT_REL_PATH
        endif
        let f = substitute(dir, p, '','')
        let dot = substitute(f,'[^/]\+/','../','g')
        return dot.tail
    endif
    return substitute(path, dir, '', '')
endfun "}}}
fun! riv#path#is_rel_to(dir, path) "{{{
    
    let dir = riv#path#is_directory(a:dir) ? a:dir : a:dir.'/'
    let dir = fnamemodify(dir, ':gs?\?/?') 
    let path = fnamemodify(a:path, ':gs?\?/?') 
    if match(path, dir) == -1
        return 0
    else
        return 1
    endif
endfun "}}}
fun! riv#path#rel_to_root(path) "{{{
    return riv#path#rel_to(riv#path#root(), a:path)
endfun "}}}
fun! riv#path#is_rel_to_root(path) "{{{
    return riv#path#is_rel_to(riv#path#root(), a:path)
endfun "}}}

fun! riv#path#par_to(dir,path) "{{{
    let dir = riv#path#is_directory(a:dir) ? a:dir : a:dir.'/'
    let dir = fnamemodify(dir, ':gs?\?/?') 
 
    let path = fnamemodify(a:path, ':gs?\?/?') 
    if match(dir, path) == -1
        throw g:_riv_e.NOT_REL_PATH
    endif
    let f = substitute(dir, path, '','')
    let dot = substitute(f,'[^/]\+/','../','g')
    return dot
endfun "}}}

fun! riv#path#is_relative(name) "{{{
    return a:name !~ '^[~/]\|^[a-zA-Z]:'
endfun "}}}
fun! riv#path#is_directory(name) "{{{
    return a:name =~ '[\\/]$' 
endfun "}}}

fun! riv#path#ext_to(file, ft) "{{{
    return fnamemodify(a:file, ":r") . '.' . a:ft
endfun "}}}
fun! riv#path#ext_tail(file, ft) "{{{
    return fnamemodify(a:file, ":t:r") . '.' . a:ft
endfun "}}}

fun! riv#path#join(a, ...)
    " python2.7/posixpath.py
    "
    " Join two or more pathname componentes,
    " inserting '/' as needed.
    " If any component is an absolute path, all previous path components
    " will be discarded.
    "
    let path = a:a
    for b in a:000
        if !riv#path#is_relative(b)
            let path = b
        elseif  path == '' ||  path =~ '/$'
            let path .= b
        else 
            let path .= '/' . b
        endif
    endfor
    return path
endfun

if expand('<sfile>:p') == expand('%:p') "{{{
    call riv#test#doctest('%','%',2)
endif "}}}
let &cpo = s:cpo_save
unlet s:cpo_save
