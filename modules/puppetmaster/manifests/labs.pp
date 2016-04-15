# Class: puppetmaster::labs
#
# This class handles the Wikimedia Labs specific bits of a Puppetmaster
class puppetmaster::labs {
    if ($::lsbdistcodename == 'precise') {
        package { 'libldap-ruby1.8': ensure => present; }
    }

    include puppetmaster::certcleaner

    cron { 'update_public_puppet_repos':
        ensure  => present,
        command => '(cd /var/lib/git/operations/puppet && /usr/bin/git pull && /usr/bin/git submodule update --init) > /dev/null 2>&1',
        user    => 'gitpuppet',
        minute  => '*/1',
    }

    cron { 'update_private_puppet_repos':
        ensure  => present,
        command => '(cd /var/lib/git/operations/labs/private && /usr/bin/git pull) > /dev/null 2>&1',
        user    => 'gitpuppet',
        minute  => '*/1',
    }

    $horizon_host_ip = ipresolve(hiera('labs_horizon_host'), 4)
    file { '/etc/puppet/auth.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppetmaster/auth-labs-master.conf.erb'),
    }
}
