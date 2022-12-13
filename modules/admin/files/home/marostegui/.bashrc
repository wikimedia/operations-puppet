alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

export PS1="[\t] \u@\h:\w\\$\[$(tput sgr0)\] "
alias mysqlbinlog='mysqlbinlog -vv --base64-output=DECODE-ROWS --skip-ssl'
