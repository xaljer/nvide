" dockerfile.vim - Syntax highlighting for Dockerfiles
" Maintainer:   Honza Pokorny <https://honza.ca>
" Version:      0.5


if exists("b:current_syntax")
    finish
endif

runtime! syntax/xml.vim

"syntax case ignore

syn keyword notice EXIF Offset OFFSET
syn match marker     '.*\<\(Marker\).*'
syn match operator   '\(@\|=\|[\|]\|*\|#\)'
syn region string    start=/"/ end=/"/ skip=/\\./

hi def link marker      DiffAdd
hi def link notice      Todo
hi def link operator    Operator
hi def link string      String

hi notice guifg=yellow

let b:current_syntax = "jpegsnoop"
