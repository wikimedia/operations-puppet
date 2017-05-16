#!/usr/bin/env bash

alias dpkg-installed="dpkg -l|grep ^ii|awk '{printf \"%-20s %s\n\", \$2, \$3}'"
alias apt-search="apt-cache search"
alias apt-install="sudo apt-get install"

