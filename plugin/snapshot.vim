if exists('g:loaded_test')
  finish
endif
let g:loaded_test = 1

command! -nargs=* -bar JumpToSnapshot call snapshot#show(split(<q-args>))
