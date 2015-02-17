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

let s:vim_options = {
      \   'swapfile':    0,
      \   'bufhidden':   'unload',
      \   'foldmethod':  'manual',
      \   'foldenable':  0,
      \   'complete':    '-wbuU',
      \   'undolevels':  -1,
      \   'eventignore': 'FileType'
      \ }

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
  if exists('b:LargeFile_store')
    call s:RestoreOptions()
  endif

  "  call Dfunc("s:LargeFile(force=".a:force." fname<".a:fname.">) g:LargeFile=".g:LargeFile)
  if a:force || s:IsLarge(a:fname)
    sil! call s:ParenMatchOff()
    syn clear

    let b:LargeFile_store = copy(s:vim_options)
    for [key, new_value] in items(b:LargeFile_store)
      let b:LargeFile_store[key] = getbufvar('%', '&l:' . key)
      if type(new_value) == type('')
        if new_value[0] =~ '\v(\+|-)'
          execute "setlocal " . key . new_value[0] . '=' . new_value[1:-1]
        else
          execute "setlocal " . key . '=' . new_value
        endif
      else
        execute "let &l:" . key . '=' . new_value
      endif
    endfor

    autocmd LargeFile BufEnter <buffer> call s:LargeBufEnter()
    autocmd LargeFile BufLeave <buffer> call s:LargeBufLeave()
    autocmd LargeFile BufUnload <buffer> call s:LargeBufUnload()
    if exists("#LargeFileRead#User")
      autocmd LargeFile BufRead <buffer> doautocmd User LargeFileRead
    endif
    call s:Msg("*NOTE* handling a large file")

    if exists("#LargeFile#User")
      doautocmd User LargeFile
    endif
  endif
  "  call Dret("s:LargeFile")
endfun

" ---------------------------------------------------------------------
" s:LargeFilePost: {{{2
fun! s:LargeFilePost()
  if exists('b:LargeFile_store') && s:IsLarge(line2byte(line("$")+1))
    call s:LargeFile(1, expand("<afile>"))
  endif
  " call Dret("s:LargeFilePost")
endfun

" ---------------------------------------------------------------------
" s:LargeBufEnter: {{{2
fun! s:LargeBufEnter()
  setlocal undolevels=-1
  setlocal eventignore=FileType
endfun

" ---------------------------------------------------------------------
" s:LargeBufLeave: {{{2
fun! s:LargeBufLeave()
  call s:RestoreOptions('undolevels', 'eventignore')
endfun

" ---------------------------------------------------------------------
" s:LargeBufUnload: {{{2
fun! s:LargeBufUnload()
  autocmd! LargeFile * <buffer>
endfun

" ---------------------------------------------------------------------
" s:IsLarge: {{{2
fun! s:IsLarge(fname_or_bytes)
  let bytes = type(a:fname_or_bytes) == type('') ?
        \ getfsize(a:fname_or_bytes) :
        \ a:fname_or_bytes
  " call Dfunc("s:IsLarge(fname_or_bytes=" . a:fname_or_bytes . ") g:LargeFile=" . g:LargeFile)
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
  autocmd! LargeFile * <buffer>
  call s:RestoreOptions()
  unlet! b:LargeFile_store

  syn on
  doau FileType
  call s:Msg("*NOTE* stopped large-file handling")
  "  call Dret("s:Unlarge")
endfun

" ---------------------------------------------------------------------
" s:RestoreOptions: {{{2
fun! s:RestoreOptions(...)
  if exists('b:LargeFile_store')
    let store = filter(copy(b:LargeFile_store), a:0 > 0 ? 'index(a:000, v:key) > -1' : '1')
    for [key, old_value] in items(store)
      if type(old_value) == type('')
        execute "setlocal " . key . '=' . old_value
      else
        execute "let &l:" . key . '=' . old_value
      endif
    endfor
  endif

  if exists("b:LF_nmpkeep")
    DoMatchParen
    unlet b:LF_nmpkeep
  endif
endfun

" ---------------------------------------------------------------------
" s:Msg: {{{2
fun! s:Msg(string)
  if get(g:, 'LargeFile_verbose', 1)
    redraw
    echohl WarningMsg | echomsg a:string | echohl None
  endif
endfun

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo

" modeline {{{1
" vim: ts=4 shiftwidth=2 fdm=marker expandtab
