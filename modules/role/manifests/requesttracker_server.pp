# https://wikitech.wikimedia.org/wiki/RT
class role::requesttracker_server {

    include ::standard
    include ::profile::requesttracker::server
}
