# parsercache (pc) specific configuration
# These are mariadb servers acting as on-disk cache for parsed wikitext

class role::mariadb::parsercache {
    include ::profile::base::production
    include ::profile::firewall
    ::profile::mariadb::firewall { 'parsercache': }

    include profile::mariadb::parsercache
}
