##
## this file managed by puppet
##
##    add the path to the mysql-at-facebook binaries to
##    the PATH.
##

(echo $PATH | grep -q mysql) || export PATH=$PATH:/usr/local/mysql/bin

