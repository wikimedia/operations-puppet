alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

export PS1="[\t] \u@\h:\w\\$\[$(tput sgr0)\]"
alias mysqlbinlog='/opt/wmf-mariadb10/bin/mysqlbinlog --defaults-file=/root/.my.cnf'
