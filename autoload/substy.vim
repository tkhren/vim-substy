" ===============================================================
" Substy - Quickly input substitution command
" ===============================================================

" Initialize variables
let g:substy#substitute_default_flag = get(g:, 'substy#substitute_default_flag', 'g')
let g:substy#_matches = []
let s:placeholder = '{textobj}'

function! s:escaped_pattern(magic, pattern_list) abort "{{{1
    let magic_chars = {
            \ '\v': '\.*+?={^$()|[&@~<>/',
            \ '\m': '\.*^$[~/',
            \ '\M': '\^$/',
            \ '\V': '\/',
            \ '': ''
            \ }
    let indicator = (a:magic ==# '\m') ? '' : a:magic
    let alist = map(a:pattern_list, {i,v -> escape(v, magic_chars[a:magic])})
    return indicator . join(alist, '\n')
endfunction
"}}}1

function! s:capture_selection(...) abort "{{{1
    let saved_register = [getreg('z', 1, 1), getregtype('z')]
    let selection_command = (a:0 > 0) ? a:1 : ''
    call feedkeys(printf('%s"zy', selection_command), 'xin')
    let lines = getreg('z', 1, 1)
    call setreg('z', saved_register[0], saved_register[1])
    return lines
endfunction
"}}}1

function! s:split_lines(text) abort "{{{1
    if type(a:text) ==# v:t_string
        return split(a:text, '\n')
    endif
    return a:text
endfunction
"}}}1

" ===============================================================
" substitution template
" ===============================================================
function! substy#substitute(magic, pattern, replacement, ...) abort "{{{1
    let flag = (a:0 > 1) ? a:1 : g:substy#substitute_default_flag

    let cmode = mode()
    let crange = (cmode ==# 'n' || cmode ==# 'v') ? '%' : "'<,'>"
    let patterns = s:split_lines(a:pattern)

    if cmode ==# 'v' && empty(patterns)
        let patterns = s:capture_selection()
    endif

    let offset = strdisplaywidth(flag) + 1
    if empty(patterns)
        let offset += strdisplaywidth(a:replacement) + 1
    endif

    let pattern = s:escaped_pattern(a:magic, patterns)
    let scommand = printf(":\<C-u>%ss/%s/%s/%s", crange, pattern, a:replacement, flag)
    call feedkeys(scommand . repeat("\<Left>", offset), 'in')
endfunction
"}}}1

function! substy#_substitute_operator(motion_wise) abort "{{{1
    let selected_text = join(s:capture_selection('`[v`]'), '\n')
    let s:operator_pattern = substitute(s:operator_pattern, s:placeholder, selected_text, 'g')
    let s:operator_replacement = substitute(s:operator_replacement, s:placeholder, selected_text, 'g')

    call substy#substitute(s:operator_magic,
                        \ s:operator_pattern,
                        \ s:operator_replacement,
                        \ s:operator_flag)
endfunction
"}}}1

function! substy#substitute_operator(magic, ...) abort "{{{1
    " substy#substitute_operator({magic}, [{pattern}], [{replacement}], [{flag}])
    " s:placeholder in the {pattern} and {replacement} will be substituted with text-object
    " noremap <expr> S substy#substitute_operator('\m', '{textobj}', '{textobj}')
    " This is hidden feature..., it may be remove in future.
    let s:operator_magic = a:magic
    let s:operator_pattern = (a:0 > 0) ? a:1 : s:placeholder
    let s:operator_replacement = (a:0 > 1) ? a:2 : ''
    let s:operator_flag = (a:0 > 2) ? a:3 : g:substy#substitute_default_flag
    set operatorfunc=substy#_substitute_operator
    return 'g@'
endfunction
"}}}1

" ===============================================================
" global substitution template
" ===============================================================
function! substy#global(magic, pattern, cmd) abort "{{{1
    let cmode = mode()
    let crange = (cmode ==# 'n' || cmode ==# 'v') ? '' : "'<,'>"
    let patterns = s:split_lines(a:pattern)

    if cmode ==# 'v' && empty(patterns)
        let patterns = s:capture_selection()
    endif

    let offset = 0
    if empty(patterns)
        let offset += strdisplaywidth(a:cmd) + 1
    endif

    let pattern = s:escaped_pattern(a:magic, patterns)
    let gcommand = printf(":\<C-u>%sg/%s/%s", crange, pattern, a:cmd)
    call feedkeys(gcommand . repeat("\<Left>", offset), 'in')
endfunction
"}}}1

function! substy#_global_operator(motion_wise) abort "{{{1
    call substy#global(s:operator_magic, s:capture_selection('`[v`]'), '')
endfunction
"}}}1

function! substy#global_operator(magic) abort "{{{1
    let s:operator_magic = a:magic
    set operatorfunc=substy#_global_operator
    return 'g@'
endfunction
"}}}1

" ===============================================================
" V global substitution template
" ===============================================================
function! substy#vglobal(magic, pattern, cmd) abort "{{{1
    let cmode = mode()
    let crange = (cmode ==# 'n' || cmode ==# 'v') ? '' : "'<,'>"
    let patterns = s:split_lines(a:pattern)

    if cmode ==# 'v' && empty(patterns)
        let patterns = s:capture_selection()
    endif

    let offset = 0
    if empty(patterns)
        let offset += strdisplaywidth(a:cmd) + 1
    endif

    let pattern = s:escaped_pattern(a:magic, patterns)
    let gcommand = printf(":\<C-u>%sv/%s/%s", crange, pattern, a:cmd)
    call feedkeys(gcommand . repeat("\<Left>", offset), 'in')
endfunction
"}}}1

function! substy#_vglobal_operator(motion_wise) abort "{{{1
    call substy#vglobal(s:operator_magic, s:capture_selection('`[v`]'), '')
endfunction
"}}}1

function! substy#vglobal_operator(magic) abort "{{{1
    let s:operator_magic = a:magic
    set operatorfunc=substy#_vglobal_operator
    return 'g@'
endfunction
"}}}1

" ===============================================================
" Extract and yank
" ===============================================================
function! substy#_yank(regname) abort "{{{1
    call setreg(a:regname, copy(g:substy#_matches))
    let g:substy#_matches = []
endfunction
"}}}1

function! substy#yank(...) abort "{{{1
    let pattern = (a:0 > 0) ? a:1 : ''
    let cmode = mode()
    let crange = "'<,'>"
    if cmode ==# 'n' || cmode ==# 'v'
        let crange = '%'
    endif

    let g:substy#_matches = []
    let replacement = printf('\=add(g:substy#_matches,submatch(%s))', v:count)
    let command1 = printf(":\<C-u>%ss/%s/%s/gn\<CR>", crange, pattern, replacement)
    let command2 = printf(":call substy#_yank('%s')\<CR>", v:register)
    call feedkeys(command1 . command2, 'in')
endfunction
"}}}1

" vim: ft=vim fenc=utf-8 ff=unix foldmethod=marker:
