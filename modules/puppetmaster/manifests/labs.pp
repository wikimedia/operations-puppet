# Class: puppetmaster::labs
#
# This class handles the Wikimedia Labs specific bits of a Puppetmaster
class puppetmaster::labs {
    if ($::lsbdistcodename == 'precise') {
        package { 'libldap-ruby1.8': ensure => present; }
    }

    include puppetmaster::autosigner

    cron { 'update_public_puppet_repos':
        ensure      => present,
        command     => '(cd /var/lib/git/operations/puppet && /usr/bin/git pull && /usr/bin/git submodule update --init) > /dev/null 2>&1',
        user        => 'gitpuppet',
        environment => 'GIT_SSH=/var/lib/git/ssh',
        minute      => '*/1',
    }

    cron { 'update_private_puppet_repos':
        ensure      => present,
        command     => '(cd /var/lib/git/operations/labs/private && /usr/bin/git pull) > /dev/null 2>&1',
        user        => 'gitpuppet',
        environment => 'GIT_SSH=/var/lib/git/ssh',
        minute      => '*/1',
    }

    # Used to contain sensitive information
    file { '/etc/labsstatus.cfg':
        ensure => absent,
    }
}
