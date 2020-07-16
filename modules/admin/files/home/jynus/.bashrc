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
alias mysqlbinlog='mysqlbinlog -vv --base64-output=DECODE-ROWS --skip-ssl'
alias ls='ls --color=auto'
alias skip-slave-start='systemctl set-environment MYSQLD_OPTS="--skip-slave-start"'
alias zarcillo='mysql.py -h db1115 -A zarcillo'

function my() {
    local instances socket socket_count has_mysql skip_ssl
    local instance="${1}"

    socket_count="$(find /run/mysqld/ -maxdepth 1 -iname "mysqld*.sock" | wc -l)"
    if [[ "${socket_count}" -eq "0" ]]; then
        socket="/tmp/mysql.sock"
    elif [[ "${socket_count}" -eq "1" ]]; then
        socket="/run/mysqld/mysqld.sock"
    else
        if [[ -z "${instance}" ]]; then
            instances="$(find /run/mysqld/ -maxdepth 1 -iname "mysqld.*.sock" -printf '%P '| sed -E 's/mysqld\.([^.]+)\.sock/\1/g')"
            echo "Multi-instance host and no instance was specified, see the autocompletion: ${instances}"
            return 1
        fi
        socket="/run/mysqld/mysqld.${instance}.sock"
    fi
    has_mysql=$(find '/opt/' -maxdepth 1 -iname "wmf-mysql*" | wc -l)
    if [[ "${has_mysql}" -eq "0" ]]; then
        skip_ssl='--skip-ssl'
    else
        skip_ssl='--ssl-mode=DISABLED'
    fi
    sudo mysql --disable-auto-rehash $skip_ssl --socket="${socket}" --user=root --prompt="\u@$(hostname)[\d]> " --pager="grcat /etc/mysql/grcat.config | less -RSFXin"
}
