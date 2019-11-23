# substy

This is a Vim plugin to provide mapping functions to quickly input substitution command.

This plugin has two main features,
which are to insert substitution template and to extract matches.

## Usage

See `doc/substy.txt` or `:h substy` for detail.

This plugin does not provide any mappings by default.
Please add the below code to your vimrc or init.vim, and map them to your prefer keys.

```
nnoremap <expr> s substy#substitute_operator('\m')
noremap <expr> ss substy#substitute('\m', '', '')
noremap <expr> s/ substy#substitute('', @/, '')
noremap <expr> s? substy#substitute('', @/, @/)
noremap <expr> s"" substy#substitute('\m', @", '')
noremap <expr> sy substy#yank()
```

### Insert substitution template

When the function `substy#substitute({magic}, {pattern}, {replacement}, [{flag}])`
is called at the normal mode, `:%s/_//g` command will be inserted to the command line.
If you defined the above mappings, only typing `ss`, you can quickly start substitution.
Where the underscore `_` stands for a cursor position.

A substitution template that is inserted by this function depends on mode context.

- Normal mode:      `:%s/{pattern}/{replacement}/{flag}`
- Visual-char mode: `:%s/{pattern}/{replacement}/{flag}`
- Visual-line mode: `:'<,'>s/{pattern}/{replacement}/{flag}`

If you defined as the `{pattern}` is blank and it is called from the Visual-char mode,
the selected text will be used as a pattern.

If the `{pattern}` is not a regular expression and includes a special character
like `[` or `/`, you should give the `{magic}` to escape the pattern
because the substitution formula will be broken.
Either `\v` (very magic), `\m` (magic), `\M` (no magic) and `\V` (very no magic)
can be used as a magic code.

`substy#substitute_operator({magic})` is an operator version of the `substy#substitute()`.
You are able to use a text-object as a pattern.
For example, if you mapped it to `s`, the following objects can be used as a pattern.

- `siw`: word under the cursor
- `si)`: text in the parentheses ()
- `s$`: text from the cursor to the end of line

Here is an example,

```
noremap <expr> ss substy#substitute('', '', '')
    "=> (NORMAL) :%s/_//g
    "=> (V-CHAR) :%s/{SELTEXT}/_/g
    "=> (V-LINE) :'<,'>s/_//g
noremap <expr> ss substy#substitute('\m', '', '')
    "=> (NORMAL) :%s/_//g
    "=> (V-CHAR) :%s/{ESCAPE(SELTEXT)}/_/g
    "=> (V-LINE) :'<,'>s/_//g
noremap <expr> ss substy#substitute('\v', '', '')
    "=> (NORMAL) :%s/\v_//g
    "=> (V-CHAR) :%s/\v{ESCAPE(SELTEXT)}/_/g
    "=> (V-LINE) :'<,'>s/\v_//g
noremap <expr> s/ substy#substitute('', @/, '')
    "=> (NORMAL) :%s/{@/}/_/g
    "=> (V-CHAR) :%s/{@/}/_/g
    "=> (V-LINE) :'<,'>s/{@/}/_/g
noremap <expr> s"" substy#substitute('\m', @", '')
    "=> (NORMAL) :%s/{ESCAPE(@")}/_/g
    "=> (V-CHAR) :%s/{ESCAPE(@")}/_/g
    "=> (V-LINE) :'<,'>s/{ESCAPE(@")}/_/g
noremap <expr> s"" substy#substitute('\v', @", '')
    "=> (NORMAL) :%s/\v{ESCAPE(@")}/_/g
    "=> (V-CHAR) :%s/\v{ESCAPE(@")}/_/g
    "=> (V-LINE) :'<,'>s/\v{ESCAPE(@")}/_/g
```

### Extract matches

`substy#yank()` is to extract matches after you searched something,
and yank into a register. The unnamed register (`"`) is used by default.

If you mapped it to `sy`, you can paste matched text with just typing `syp`
after you searched something.
If you need to use the other registers, please type as like `"zsyp`.
And if you need submatch, please use `{count}` feature.
For example, after you searched `/\v(\w+)\s*:\s*(\w+)` on a JSON buffer,
`1sy` extracts a key list, and `2sy` extracts a value list.


## Installation

Please install with your favorite plugin manager.

I recommend not to set `set gdefault` and `set nomagic` due to unexpected behavior.

```
call dein#add('tkhren/vim-substy')
```
