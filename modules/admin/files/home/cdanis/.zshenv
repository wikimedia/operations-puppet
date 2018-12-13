alias ls='ls --color=auto'
alias grep='grep --color=auto'
if [[ $(hostname -f) = install*wikimedia* ]]; then
    export REPREPRO_BASE_DIR=/srv/wikimedia
    export GNUPGHOME=/root/.gnupg
fi
