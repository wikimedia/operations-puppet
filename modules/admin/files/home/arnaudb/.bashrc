# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

### Aliasing
alias grep='rg'
alias cp='cp -i'
alias l="ls -l --color"
alias la="ls -al --color"
alias ls='ls --color=auto'
alias mv='mv -i'
alias mysqlbinlog='mysqlbinlog -vv --base64-output=DECODE-ROWS --skip-ssl'
alias rm='rm -i'
alias skip-slave-start='systemctl set-environment MYSQLD_OPTS="--skip-slave-start"'
# alias zarcillo='mysql.py -h db1215 -A zarcillo'

### Functions
function prompt_return_code_handle(){
    if [[ $? -eq 0 ]]; then
        echo "$(tput sgr0)\$ "
    else
        echo "$(tput setaf 196)\$ $(tput sgr0)"
    fi
}

function my() {
    local instances socket socket_count has_mysql skip_ssl
    local instance="${1}"
    local single_socket="/run/mysqld/mysqld.sock"

    socket_count="$(find /run/mysqld/ -maxdepth 1 -iname "mysqld*.sock" | wc -l)"
    if [[ ( "${socket_count}" -eq "1" && -a $single_socket ) ]]; then
        socket=$single_socket
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

function quick_show_slave() {
    sudo mysql -e 'show slave status \G'|grep -i 'second|run|state|log_|Master_Host|Exec'
    echo "######"
    sudo mysql -e 'SELECT greatest(0, TIMESTAMPDIFF(MICROSECOND, max(ts), UTC_TIMESTAMP(6)) - 500000)/1000000 FROM heartbeat.heartbeat ORDER BY ts LIMIT 1;'
    echo "######"
}

function watch_replication(){
    while : ; do quick_show_slave ; sleep 1 ; done
}

function disable_semi_sync(){
    sudo mysql -e "STOP SLAVE ; SET GLOBAL rpl_semi_sync_slave_enabled=OFF; START SLAVE; "
}

### Exporting
export HISTFILESIZE=100000
export HISTIGNORE="ls:cd:git"
export HISTTIMEFORMAT="%d/%m/%y %T "


### Sourcing
if [ -f /etc/bash_completion.d/mysql ]; then
    . /etc/bash_completion.d/mysql
fi

if [ -f /home/arnaudb/.local/bin/z.sh ]; then
    . /home/arnaudb/.local/bin/z.sh
fi


#### Prompt rendering
if [ $(id -u) -eq 0 ]; then
#    PS1="\[\e[38;5;196m\]\u\[\e[38;5;202m\]@\[\e[38;5;208m\]\h \[\e[38;5;220m\]\w \$(prompt_return_code_handle)"
   export PS1='\[\033[0;94m\]\u@\h\[\033[1m\]:\[\033[0;35m\]\W\[\033[0m\] $ '
else
#    export PS1="\[\e[38;5;47m\]\u\[\e[38;5;156m\]@\[\e[38;5;227m\]\h \[\e[38;5;231m\]\w \$(prompt_return_code_handle)"
   export PS1='\[\033[0;94m\]\u@\h\[\033[1m\]:\[\033[0;35m\]\W\[\033[0m\] $ '
fi
