# https://gitlab.wikimedia.org/
# https://phabricator.wikimedia.org/project/view/5057/
class role::gitlab {
    include profile::base::production
    include profile::firewall
    include profile::firewall::nftables_throttling
    include profile::prometheus::nft_throttling_denylist
    include profile::backup::host
    include profile::gitlab
}
