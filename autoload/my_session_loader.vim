" I consulted unite.vim/plugin/unite/buffer.vim for which events to autocmd and how to handle them.

let g:my_session_loader_session_file_name = ".session_files.txt"
let g:my_session_loader_how_many_files_to_save = 5

function! my_session_loader#load() abort
  if filereadable(g:my_session_loader_session_file_name)
    for path in readfile(g:my_session_loader_session_file_name)
      if filereadable(path)
        call my_session_loader#add_buffer(path)
      endif
    endfor
  endif
endfunction

function! my_session_loader#enable_auto_save() abort
  augroup my_session_loader
    autocmd!
    autocmd BufEnter,BufWinEnter,BufFilePost * call my_session_loader#add_loading_buffer()
    autocmd BufDelete,BufWipeout * call my_session_loader#remove_unloading_buffer()
    autocmd VimLeave * call my_session_loader#save()
  augroup END
endfunction

function! my_session_loader#disable_auto_save() abort
  augroup my_session_loader
    autocmd!
  augroup END
endfunction

" Usually you shouldn't view/edit this!
let g:_my_session_loader_loaded_files = {}
let g:_my_session_loader_count = 0

function! s:compare_by_order(file1, file2) abort
  return a:file1.order == a:file2.order ? 0 : a:file1.order > a:file2.order ? 1 : -1
endfunction

function! my_session_loader#save() abort
  call filter(g:_my_session_loader_loaded_files,
        \ 'buflisted(str2nr(v:key)) && filereadable(v:val.path)')
  let files = (values(g:_my_session_loader_loaded_files))
  call sort(files, funcref("s:compare_by_order"))
  call map(files, { _idx, file -> file.path })
  " Save only recently opened N files,
  " where N is g:my_session_loader_how_many_files_to_save.
  let length = len(files)
  let files = length > g:my_session_loader_how_many_files_to_save ? files[(length - g:my_session_loader_how_many_files_to_save):] : files
  call writefile(files, g:my_session_loader_session_file_name)
endfunction

function! my_session_loader#add_buffer(path) abort
  " NOTE: bufadd doesn't work with my-project-opener.vim...
  "let buffer_number = bufadd(a:path)
  let path = substitute(a:path, '\', '/', 'g')
  execute "edit " . path
  let buffer_number = bufnr('%')
  call s:add_path(buffer_number, path)
endfunction

function! my_session_loader#add_loading_buffer() abort
  let path = expand('<amatch>:.')
  let buffer_number = bufnr('%')

  if bufname(buffer_number) == '' || buffer_number != expand('<abuf>') || &buftype != ''
    return
  endif

  call s:add_path(buffer_number, path)
endfunction

function! s:add_path(buffer_number, path) abort
  let g:_my_session_loader_count += 1
  let g:_my_session_loader_loaded_files[a:buffer_number] = {
        \ "path": substitute(a:path, '\', '/', 'g'),
        \ "order": g:_my_session_loader_count
        \ }
endfunction

function! my_session_loader#remove_unloading_buffer() abort
  let buffer_number = bufnr('%')

  if bufname(buffer_number) == '' || buffer_number != expand('<abuf>')
    return
  endif

  if has_key(g:_my_session_loader_loaded_files, buffer_number)
    call remove(g:_my_session_loader_loaded_files, buffer_number)
  endif
endfunction
