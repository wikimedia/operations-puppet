export EDITOR=vim
export DEBEMAIL=jbond@wikimedia.org
export DEBFULLNAME="John Bond"
export SITE=$(hostname -d | cut -d\. -f1)
# Used to ensure you hit the local site lvs server
# curl-lvs https://dbtree.wikimedia.org
alias curl-lvs='curl --connect-to "::text-lb.${SITE}.wikimedia.org"'
if [[ $(hostname -f) == cp*wmnet ]]
then
  # Used from caching servers to hit the to ensure you hit the front end ats instance e.g
  # curl-fe https://dbtree.wikimedia.org
  alias curl-fe='curl --connect-to "::$HOSTNAME"'
  # or back end
  # curl-be https://dbtree.wikimedia.org
  alias curl-be='curl --connect-to "::$HOSTNAME:3128"   -H "X-Forwarded-Proto: https"'
fi
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias lsof_del='sudo lsof +c 15 -nXd DEL'
if [[ $(hostname -f) = apt*wikimedia* ]]; then
    export REPREPRO_BASE_DIR=/srv/wikimedia
    export GNUPGHOME=/root/.gnupg
fi
