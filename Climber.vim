nnoremap <space> :call StartClimbing()<CR>
vnoremap <space> :<C-u>call ClimbUp()<CR>
vnoremap <S-space> :<C-u>call ClimbDown()<CR>

function! Concat(l1, l2)
    let new_list = deepcopy(a:l1)
    call extend(new_list, a:l2)
    return new_list
endfunction

let g:unnested = ['"', "'"]
let g:climb_delimitors = { ")": "(", "}": "{", '\]': '\['}
let g:opening_delimitors = keys(g:climb_delimitors)
let g:closing_delimitors = values(g:climb_delimitors)
let g:all_delimitors = Concat(g:opening_delimitors, g:closing_delimitors)
let g:delimitor_pattern = '\(' . join(g:all_delimitors, '\)\|\(' ) . '\)'
let g:history = []

function! StartClimbing()
  let g:history = []
  execute "normal! viw"
endfunction 

function! ClimbUp()
  call Push(g:history, getpos("."))
  execute "normal `>"
  call Climb()
endfunction

function! ClimbDown()
  if Empty(g:history)
    return
  endif

  let last_pos = Pop(g:history)
  call setpos(".", last_pos)

  if Empty(g:history)
    execute "normal! \<esc>viw"
    return
  endif

  call Climb()
endfunction

function! Climb()
  let closing = LookFor(InitialPattern(),"f", 0)
  let delim = get(g:all_delimitors, closing)
  normal mo

  if closing >= 0
    call LookFor(MatchingDelimitorPattern(delim), "b", 0)
    normal mc
    execute "normal! `ov`c"
  endif
endfunction

function! InitialPattern()
  return BuildPattern(keys(g:climb_delimitors), values(g:climb_delimitors))
endfunction

function! MatchingDelimitorPattern(delimitor)
  if index(g:unnested, a:delimitor) >= 0
    return BuildPattern([], [a:delimitor])
  else
    return BuildPattern([a:delimitor], [g:climb_delimitors[a:delimitor]])
  endif
endfunction

function! BuildPattern(closing_delimitors, opening_delimitors)
  let all_delimitors = Concat(a:closing_delimitors, a:opening_delimitors)
  let delimitor_pattern = '\(' . join(all_delimitors, '\)\|\(' ) . '\)'
  return {"pattern-string": delimitor_pattern, "closing-delimitors-list": a:closing_delimitors}
endfunction

function! LookFor(pattern, direction, depth)
  let found = ScanForDelim(a:pattern, a:direction) 
  if found < 0
    return found
  endif

  let matching = MatchesDirection(a:pattern, a:direction, found)
  if matching
    if a:depth == 0
      return found
    else
      return LookFor(a:pattern, a:direction, a:depth - 1)
    endif
  else
    return LookFor(a:pattern, a:direction, a:depth + 1)
  endif
endfunction


" Pattern is actually a map of {"pattern-string": "()", "closing-delimitors-list": []}
" Direction is either b for backwards or f for forwards
" Returns index of match (inside pattern-list
" or a negative number in case of no match.)
function! ScanForDelim(pattern, direction)
  let direction_flag = (a:direction ==# "b") ? "b" : ""
  let flags = direction_flag . "pW"


  let search_match = search(a:pattern["pattern-string"], flags)


  return search_match - 2
endfunction

function! MatchesDirection(pattern, direction, found)
  let delimiter_list = a:pattern["closing-delimitors-list"]
  " Closing delimitors match forward direction
  " Opening delimitors match backward direction

  let delim_direction = (a:found < len(delimiter_list) ? "f" : "b" )

  return a:direction ==# delim_direction "looking backwards
endfunction

function! NewDict(k, v)
  let dict = {}
  let dict[a:k] = a:v
  return dict
endfunction

function! Push(stack, new_element)
  call add(a:stack, a:new_element)
endfunction

function! Pop(stack)
  let size = len(a:stack)
  let last_element = get(a:stack, size - 1)
  call remove(a:stack, size - 1)
  return last_element
endfunction

function! Empty(stack)
  return empty(a:stack)
endfunction

function! First(stack)
  return len(a:stack) == 1
endfunction

