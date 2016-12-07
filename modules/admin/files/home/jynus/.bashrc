# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

if [ $(id -u) -eq 0 ]; then
    PS1="\[\e[7;49;31m\]\u@\h:\w\[\e[0m\]\$ "
else
    PS1="\[\e[1;31m\]\u@\h\[\e[0m\]:\[\e[01;34m\]\w\[\e[0m\]\$ "
fi
alias my='mysql --skip-ssl --host=localhost --user=root --prompt="\u@\h[\d]> " --pager="grcat /etc/mysql/grcat.config | less -RSFXin"'
alias mysqlbinlog='mysqlbinlog -vv --base64-output=DECODE-ROWS --skip-ssl'
alias ls='ls --color=auto'
