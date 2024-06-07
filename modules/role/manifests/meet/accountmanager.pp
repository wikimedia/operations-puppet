# account manager for Wikimedia Meet
# https://phabricator.wikimedia.org/tag/wikimedia_meet/
class role::meet::accountmanager {
    include profile::base::production
    include profile::backup::host
    include profile::firewall
    include profile::meet::accountmanager
}
