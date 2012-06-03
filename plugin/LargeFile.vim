" LargeFile: Sets up an autocmd to make editing large files work with celerity
"   Author:     Charles E. Campbell, Jr.
"   Date:       May 18, 2011
"   Version:    5i ASTRO-ONLY
"   Copyright:  see :help LargeFile-copyright
" GetLatestVimScripts: 1506 1 :AutoInstall: LargeFile.vim

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_LargeFile") || &cp
  finish
endif
let g:loaded_LargeFile = "v5i"
let s:keepcpo          = &cpo
set cpo&vim

" ---------------------------------------------------------------------
" Commands: {{{1
com! Unlarge            call s:Unlarge()
com! -bang Large        call s:LargeFile(<bang>0,expand("%"))

" ---------------------------------------------------------------------
"  Options: {{{1
if !exists("g:LargeFile")
  let g:LargeFile = 20
endif

if !exists("g:LargeFile_patterns")
  let g:LargeFile_patterns = '*'
endif

" ---------------------------------------------------------------------
"  LargeFile Autocmd: {{{1
" for large files: turns undo, syntax highlighting, undo off etc
" (based on vimtip#611)
augroup LargeFile
  au!
  execute 'autocmd LargeFile BufReadPre ' .
        \ g:LargeFile_patterns .
        \ ' call <SID>LargeFile(0, expand("<afile>"))'
  execute 'autocmd LargeFile BufReadPost ' .
        \ g:LargeFile_patterns .
        \ ' call <SID>LargeFilePost()'
augroup END

" ---------------------------------------------------------------------
" s:LargeFile: {{{2
fun! s:LargeFile(force,fname)
  "  call Dfunc("s:LargeFile(force=".a:force." fname<".a:fname.">) g:LargeFile=".g:LargeFile)
  if a:force || s:IsLarge(a:fname)
    sil! call s:ParenMatchOff()
    syn clear
    let b:LargeFile_mode = 1
    "   call Decho("turning  b:LargeFile_mode to ".b:LargeFile_mode)
    let b:LF_bhkeep      = &l:bh
    let b:LF_cptkeep     = &cpt
    let b:LF_eikeep      = &ei
    let b:LF_fdmkeep     = &l:fdm
    let b:LF_fenkeep     = &l:fen
    let b:LF_swfkeep     = &l:swf
    let b:LF_ulkeep      = &ul
    set ei=FileType
    setlocal noswf bh=unload fdm=manual ul=-1 nofen cpt-=wbuU
    au LargeFile BufEnter <buffer> set ul=-1
    exe "au LargeFile BufLeave <buffer> let &ul=".b:LF_ulkeep."|set ei=".b:LF_eikeep
    au LargeFile BufUnload <buffer> au! LargeFile * <buffer>
    echomsg "***note*** handling a large file"
  endif
  "  call Dret("s:LargeFile")
endfun

" ---------------------------------------------------------------------
" s:LargeFilePost: {{{2
fun! s:LargeFilePost()
  if get(b:, 'LargeFile_mode', 1) == 0 && s:IsLarge(line2byte(line("$")+1))
    call s:LargeFile(1, expand("<afile>"))
  endif
  " call Dret("s:LargeFilePost")
endfun

" ---------------------------------------------------------------------
" s:IsLarge: {{{2
fun! s:IsLarge(fname_or_bytes)
  let bytes = type(a:fname_or_bytes) == type('') ?
        \ getfsize(a:fname_or_bytes) :
        \ a:fname_or_bytes
  " call Dfunc("s:IsLarge(fname_or_bytes=" . a:fname_or_bytes . ") g:LargeFile=" . g:LargeFile . " b:LargeFile_mode=" . get(b:, 'LargeFile_mode', '(not set)'))
  return bytes >= g:LargeFile * get(g:, 'LargeFile_size_unit', 1024 * 1024) || bytes <= -2
endfun

" ---------------------------------------------------------------------
" s:ParenMatchOff: {{{2
fun! s:ParenMatchOff()
  "  call Dfunc("s:ParenMatchOff()")
  redir => matchparen_enabled
  com NoMatchParen
  redir END
  if matchparen_enabled =~ 'g:loaded_matchparen'
    let b:LF_nmpkeep= 1
    NoMatchParen
  endif
  "  call Dret("s:ParenMatchOff")
endfun

" ---------------------------------------------------------------------
" s:Unlarge: this function will undo what the LargeFile autocmd does {{{2
fun! s:Unlarge()
  "  call Dfunc("s:Unlarge()")
  let b:LargeFile_mode= 0
  "  call Decho("turning  b:LargeFile_mode to ".b:LargeFile_mode)
  if exists("b:LF_bhkeep") |let &l:bh  = b:LF_bhkeep |unlet b:LF_bhkeep |endif
  if exists("b:LF_fdmkeep")|let &l:fdm = b:LF_fdmkeep|unlet b:LF_fdmkeep|endif
  if exists("b:LF_fenkeep")|let &l:fen = b:LF_fenkeep|unlet b:LF_fenkeep|endif
  if exists("b:LF_swfkeep")|let &l:swf = b:LF_swfkeep|unlet b:LF_swfkeep|endif
  if exists("b:LF_ulkeep") |let &ul    = b:LF_ulkeep |unlet b:LF_ulkeep |endif
  if exists("b:LF_eikeep") |let &ei    = b:LF_eikeep |unlet b:LF_eikeep |endif
  if exists("b:LF_cptkeep")|let &cpt   = b:LF_cptkeep|unlet b:LF_cptkeep|endif
  if exists("b:LF_nmpkeep")
    DoMatchParen
    unlet b:LF_nmpkeep
  endif
  syn on
  doau FileType
  echomsg "***note*** stopped large-file handling"
  "  call Dret("s:Unlarge")
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo

" modeline {{{1
" vim: ts=4 shiftwidth=2 fdm=marker expandtab
