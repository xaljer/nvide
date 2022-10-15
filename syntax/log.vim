" Vim syntax file
" Language: Generic log files
" Version: 1.11

if exists("b:current_syntax")
  finish
endif

syn match log_date          '\(Jan\|Feb\|Mar\|Apr\|May\|Jun\|Jul\|Aug\|Sep\|Oct\|Nov\|Dec\) [ 0-9]\d *' containedin=ALL
syn match log_date          '\(\d\{4}-\)\{0,1}\d\d-\d\d' containedin=ALL

syn match log_timestamp     '\[\d\{8}\]' containedin=ALL
syn match log_time          '\d\d:\d\d:\d\d\(\.\d\d\d\)\{0,1}\s*' containedin=ALL
syn match log_time          '\c\d\d:\d\d:\d\d\(\.\d\+\)\=\([+-]\d\d:\d\d\|Z\)' containedin=ALL

syn match log_info          '.*\(\[INFO\]\|\[I\]\).*'
syn match log_notice        '\c.*\<\(NOTICE\).*'
syn match log_notice        '[\+\-\=\*\#]\{6,}'
syn match log_warning       '\c.*\<\(WARN\|TIMEOUT\|KILL\|NULL\|UNKNOWN\|UNSUPPORT\(ED\)\?\|INVALID\|ILLEGAL\|ABNORMAL\).*'
syn match log_warning       '^\[\d\{8}\]\[W\].*'
syn match log_error         '\c.*\<\(ERR[^NO]\|ERROR\|FAIL\|FAILED\|FAILURE\|FAULT\|FATAL\).*'
syn match log_error         '\c.*\<\(exception\|Oops\|crash\|assert\|panic\|lowmemorykiller\|NG\).*'
syn match log_error         '^\[\d\{8}\]\[E\].*'
syn match log_ok            '\c.*\<\(OK\|PASSED\|SUCCESS\|SUCCESSFUL\|SUCCEED\).*'

syn match log_notice_word   '\c\<\(START\(ING\|ED\)\?\|STOP\(PING\|PED\)\?\|BEGIN\(NING\)\?\|END\)' containedin=log_info
syn match log_notice_word   '\c\<\(ENTER\(ING\)\?\|EXIT\(ING\)\?\|OPEN\(ING\ED\)\?\|CLOSE\(D\)\?\|CLOSING\)' containedin=log_info
syn match log_notice_word   '\c\<\(CREATE\(D\)\?\|CREATING\|DESTROY\|INIT\(IAL\)\?\|DEINIT\(IAL\)\?\)' containedin=log_info
syn match log_notice_word   '\c\<\(DONE\|FINISH\(ED\)\?\|ENABLE\(D\)\?\|DISABLE\(D\)\?\)' containedin=log_info
syn match log_notice_word   '\c\<\(FULL\|SLOW\|TOO LONG\|ERRNO\)' containedin=log_info
syn match log_filename      '\(\(DCIM\\\d\{3}MEDIA\\\)\{0,1}DJI_\d\{4}\(_\w*\)\{0,1}\.\w\{3}\)' containedin=ALL
syn match log_filename      '\(DCIM/\w\w\w_\d\{12}_\d\{3}/\)\{0,1}\w\w\w_\d\{14}_\d\{4}_\w*\(\.\w\{3,4}\)\{0,1}' containedin=ALL
syn match log_filename      'DCIM/DJI_\d\{12}_\d\{3}' containedin=ALL


" ==== link to default color ====
"hi def link log_string     String
"hi def link log_number     Number
hi def link log_date        Constant
hi def link log_time        Type
hi def link log_timestamp   Directory
hi def link log_error       ErrorMsg
hi def link log_warning     WarningMsg
hi def link log_notice      Todo
hi def link log_info        Constant
hi def link log_ok          Title
hi def link log_notice_word Label
hi def link log_filename    MatchParen

" ==== redefine color ====
"hi log_ok guifg=green

let b:current_syntax = "log"

