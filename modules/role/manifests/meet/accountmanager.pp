# account manager for Wikimedia Meet
# https://phabricator.wikimedia.org/tag/wikimedia_meet/
class role::meet::accountmanager {

    system::role { 'meet::accountmanager':
        description => 'account manager for Wikimedia Meet'
    }

    include ::profile::base::production
    include ::profile::backup::host
    include ::profile::base::firewall
    include ::profile::meet::accountmanager
}
