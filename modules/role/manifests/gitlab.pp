# https://gitlab.wikimedia.org/
# https://phabricator.wikimedia.org/project/view/5057/
class role::gitlab {

    system::role { 'gitlab':
        description => 'A virtual machine running gitlab.',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::gitlab
}
