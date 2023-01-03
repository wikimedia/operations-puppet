alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

export PS1="[\t] \u@\h:\w\\$\[$(tput sgr0)\] "
alias mysqlbinlog='mysqlbinlog -vvv --base64-output=DECODE-ROWS --skip-ssl'
