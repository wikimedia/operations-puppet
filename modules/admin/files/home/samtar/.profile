#!/bin/bash
export PATH=$PATH:~/bin

# Set up some colours
RED='\033[0;31m'
NC='\033[0m' # reset colour

# Set up git
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUPSTREAM="auto verbose"
. /etc/bash_completion.d/git-prompt
PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '

# Subtle reminder
echo -e "${RED}You are on a production system!${NC}"

if [[ $(hostname -s) = deploy* ]]; then
    # Deployment advice
    echo "Deployment: https://wikitech.wikimedia.org/wiki/Backport_windows/Deployers"
fi
