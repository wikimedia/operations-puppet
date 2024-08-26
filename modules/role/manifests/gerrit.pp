# server running Gerrit code review software
# https://en.wikipedia.org/wiki/Gerrit_%28software%29
#
class role::gerrit {
    include profile::base::production
    include profile::backup::host
    include profile::firewall
    include profile::firewall::nftables_throttling
    # lint:ignore:wmf_styleguide - It is neither a role nor a profile
    include ::passwords::gerrit
    # lint:endignore
    include profile::gerrit
    include profile::gerrit::proxy
    include profile::gerrit::migration
    include profile::prometheus::apache_exporter
    include profile::prometheus::nft_throttling_denylist
    include profile::java
}
