" File:        vroom.vim
" Description: Vim plugin to run your Ruby tests
" Maintainer:  Mike Skalnik <hi@mikeskalnik.com>
" License:     MIT
" Version:     1.0
" Notes:       This code was originally pulled from Gary Bernhardt's .vimrc

command! -nargs=0 VroomRunTestFile call vroom#RunTestFile()
command! -nargs=0 VroomRunNearestTest call vroom#RunNearestTest()

if !exists("g:vroom_map_keys")
  let g:vroom_map_keys = 1
endif

if g:vroom_map_keys
  map <unique> <Leader>r :VroomRunTestFile<CR>
  map <unique> <Leader>R :VroomRunNearestTest<CR>
endif
