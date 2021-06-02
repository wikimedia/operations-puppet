# a placeholder role for a manual gitlab setup by
# https://phabricator.wikimedia.org/T274458
class role::gitlab {

    system::role { 'gitlab':
        description => 'A virtual machine running gitlab.',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::gitlab
}
