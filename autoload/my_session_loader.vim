" I consulted unite.vim\plugin\unite\buffer.vim for which events to autocmd and how to handle them.

let g:my_session_loader_session_file_name = ".session_files.txt"

function! my_session_loader#load() abort
  if filereadable(g:my_session_loader_session_file_name)
    for path in readfile(g:my_session_loader_session_file_name)
      call my_session_loader#add_buffer(path)
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

function! my_session_loader#save()
  call filter(g:_my_session_loader_loaded_files,
        \ 'buflisted(str2nr(v:key)) && filereadable(a:buffers_dictionary[v:key])')
  call writefile(values(g:_my_session_loader_loaded_files), g:my_session_loader_session_file_name)
endfunction

function! my_session_loader#add_buffer(path) abort
  " NOTE: bufadd doesn't work with my-project-opener.vim...
  "let buffer_number = bufadd(a:path)
  execute "edit " . a:path
  let buffer_number = bufnr('%')
  let g:_my_session_loader_loaded_files[buffer_number] = a:path
endfunction

function! my_session_loader#add_loading_buffer()
  let path = expand('<amatch>:.')
  let buffer_number = bufnr('%')

  if bufname(buffer_number) == '' || buffer_number != expand('<abuf>') || &buftype != ''
    return
  endif

  let g:_my_session_loader_loaded_files[buffer_number] = path
endfunction

function! my_session_loader#remove_unloading_buffer()
  let buffer_number = bufnr('%')

  if bufname(buffer_number) == '' || buffer_number != expand('<abuf>')
    return
  endif

  if has_key(g:_my_session_loader_loaded_files, buffer_number)
    call remove(g:_my_session_loader_loaded_files, buffer_number)
  endif
endfunction
