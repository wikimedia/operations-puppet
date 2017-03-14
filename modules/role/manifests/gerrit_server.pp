# server running Gerrit code review software
# https://en.wikipedia.org/wiki/Gerrit_%28software%29
#
class role::gerrit_server {

    include ::standard
    include ::profile::gerrit::server
    include ::role::backup::host
}
