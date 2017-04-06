# server running Gerrit code review software
# https://en.wikipedia.org/wiki/Gerrit_%28software%29
#
class role::gerrit::server {
    include ::standard
    include ::profile::gerrit::server
    include ::profile::backup::host
}
