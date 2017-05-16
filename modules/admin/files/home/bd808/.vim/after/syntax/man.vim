syn match  manSectionHeading    "^\s\+[0-9]\+\.[0-9.]*\s\+[A-Z].*$" contains=manSectionNumber
syn match  manSectionNumber     "^\s\+[0-9]\+\.[0-9]*"              contained
syn region manDQString          start='[^a-zA-Z"]"[^", )]'lc=1      end='"'         contains=manSQString
syn region manSQString          start="[ \t]'[^', )]"lc=1           end="'"
syn region manSQString          start="^'[^', )]"lc=1               end="'"
syn region manBQString          start="[^a-zA-Z`]`[^`, )]"lc=1      end="[`']"
syn region manBQSQString        start="``[^),']"                    end="''"
syn match  manBulletZone        transparent "^\s\+o\s" contains=manBullet
syn case    match
syn keyword manBullet contained o
syn match   manBullet contained "\[+*]"
syn match   manSubSectionStart  "^\*"   skipwhite nextgroup=manSubSection
syn match   manSubSection       ".*$"   contained

hi link manSectionNumber    Number
hi link manDQString         String
hi link manSQString         String
hi link manBQString         String
hi link manBQSQString       String
hi link manBullet           Special
hi manSubSectionStart       term=NONE cterm=NONE gui=NONE ctermfg=black ctermbg=black guifg=navyblue guibg=navyblue
hi manSubSection            term=underline cterm=underline gui=underline ctermfg=green guifg=green
set ts=8
set wrap
