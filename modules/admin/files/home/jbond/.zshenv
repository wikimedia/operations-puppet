alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias lsof_del='sudo lsof +c 15 -nXd DEL'
if [[ $(hostname -f) = install*wikimedia* ]]; then
    export REPREPRO_BASE_DIR=/srv/wikimedia
    export GNUPGHOME=/root/.gnupg
fi
export EDITOR=vim
export DEBEMAIL=jbond@wikimedia.org
export DEBFULLNAME="John Bond"
