" Minimize delay before waiting for escape key
" see https://www.johnhawthorn.com/2012/09/vi-escape-delays/
set timeoutlen=1000 ttimeoutlen=0

" remap ; to : to save a keypress for colon commands
:nmap ; :

" show our character position in the bottom right
:set ruler
