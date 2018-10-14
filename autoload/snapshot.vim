if !exists('g:jest_file_pattern')
  let g:jest_file_pattern = '\v(__tests__/.*|(spec|test))\.(js|jsx|coffee|ts|tsx)$'
endif

let test_patterns = {
  \ 'test': ['\v^\s*%(it|test)\s*[( ]\s*%("|''|`)(.*)%("|''|`)'],
  \ 'namespace': ['\v^\s*%(describe|suite|context)\s*[( ]\s*%("|''|`)(.*)%("|''|`)'],
\}

function! snapshot#show() abort
  " are we in a test file?
  if !s:jest_test_file(expand('%'))
    call s:echo_failure('Filename doesn\'t look like a test file') | return
  endif

  " figure out snapshot filename
  let snapshot_file = s:snapshot_filename(expand('%'))

  " does file exist
  if !filereadable(snapshot_file)
    call s:echo_failure('Could not find snapshot file') | return
  endif

  " find nearest snapshot string
  let position = s:get_position(expand('%'))

  " try to find snapshot string in file
  " found: jump to it
  " not found: message
endfunction

function! s:snapshot_filename(filename) abort
  let folder = fnamemodify(a:filename, ':h')
  let file = fnamemodify(a:filename, ':t')
  return folder .'/__snapshots__/'. file .'.snap'
endfunction

function! s:jest_test_file(file) abort
  return a:file =~# g:jest_file_pattern
endfunction

function! s:get_position(path) abort
  let filename_modifier = get(g:, 'test#filename_modifier', ':.')

  let position = {}
  let position['file'] = fnamemodify(a:path, filename_modifier)
  let position['line'] = a:path == expand('%') ? line('.') : 1
  let position['col']  = a:path == expand('%') ? col('.') : 1

  return position
endfunction

function! s:get_test_string(position) abort
  let name = s:nearest_test(a:position, test_patterns)
  return (len(name['namespace']) ? '^' : '') .
       \ s:escape_regex(join(name['namespace'] + name['test'])) .
       \ (len(name['test']) ? '$' : '')
endfunction

function! s:echo_failure(message) abort
  echohl WarningMsg
  echo a:message
  echohl None
endfunction

" Takes a position and a dictionary of patterns, and returns list of strings
" that were matched in the file by the patterns from the given position
" upwards. It can be used when a runner doesn't support running nearest tests
" with line numbers, but supports regexes.
"
" The "position" argument is a dictionary created by this plugin:
"
"   {
"     'file': 'test/foo_test.rb',
"     'line': 11,
"     'col': 2,
"   }
"
" The "patterns" argument is a dictionary where keys are either "test" or
" "namespace", and values are lists of regexes:
"
"   {
"     'test': ['\v^\s*def (test_\w+)'],
"     'namespace': ['\v^\s*%(class|module) (\S+)'],
"   }
"
" If a line is matched, the substring corresponding to the 1st match group will
" be returned. So for the above patterns this function might return something
" like this:
"
"   {
"     'test': ['test_calculates_time'],
"     'namespace': ['CalculatorTest'],
"   }
function! s:nearest_test(position, patterns) abort
  let test        = []
  let namespace   = []
  let last_indent = -1

  for line in reverse(getbufline(a:position['file'], 1, a:position['line']))
    let test_match      = s:find_match(line, a:patterns['test'])
    let namespace_match = s:find_match(line, a:patterns['namespace'])

    let indent = len(matchstr(line, '^\s*'))
    if !empty(test_match) && last_indent == -1
      call add(test, filter(test_match[1:], '!empty(v:val)')[0])
      let last_indent = indent
    elseif !empty(namespace_match) && (indent < last_indent || last_indent == -1)
      call add(namespace, filter(namespace_match[1:], '!empty(v:val)')[0])
      let last_indent = indent
    endif
  endfor

  return {'test': test, 'namespace': reverse(namespace)}
endfunction

function! s:find_match(line, patterns) abort
  let matches = map(copy(a:patterns), 'matchlist(a:line, v:val)')
  return get(filter(matches, '!empty(v:val)'), 0, [])
endfunction

function! s:escape_regex(string) abort
  return escape(a:string, '?+*\^$.|{}[]()')
endfunction
