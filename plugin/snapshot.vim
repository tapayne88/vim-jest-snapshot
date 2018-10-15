if exists('g:loaded_snapshot')
  finish
endif
let g:loaded_snapshot = 1

command! -nargs=* -bar JumpToSnapshot call snapshot#show(split(<q-args>))
