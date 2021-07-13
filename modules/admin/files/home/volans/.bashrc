# ~/.bashrc: executed by bash(1) for non-login shells.

function __prompt_command() {
    local ret="${?}";
    local ret_color="2";
    PS1="\[\033[48;5;1m\]\[\033[01;37m\] \h \[\033[00m\] ";
    if [[ "${ret}" -ne "0" ]]; then
        ret_color="1";
    fi;
    PS1+="\[\033[1;38;5;${ret_color}m\]${ret}\[\033[00m\] ";
    PS1+="\t \[\033[01;36m\]\w\[\033[00m\] \$ ";
}

PROMPT_COMMAND=__prompt_command

# Safe aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# Useful aliases
alias top='top -cd 1'
alias free='free -m'
alias ppless='sudo less -R /var/log/puppet.log'

# ls aliases
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lAhrt'
alias l='ls $LS_OPTIONS -lAh'

# Bash history
export HISTCONTROL=ignoreboth
export HISTSIZE=30000
export HISTFILESIZE=50000
shopt -s histappend

# MySQL universal connector
function my() {
    local instances socket socket_count
    local instance="${1}"

    socket_count="$(find /run/mysqld/ -maxdepth 1 -iname "*.sock" | wc -l)"
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
    sudo mysql --skip-ssl -S "${socket}"
}
