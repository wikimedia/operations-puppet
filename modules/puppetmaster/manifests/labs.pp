# Class: puppetmaster::labs
#
# This class handles the Wikimedia Labs specific bits of a Puppetmaster
class puppetmaster::labs {
    package { 'libldap-ruby1.8': ensure => latest; }
    # Use a specific revision for the checkout, to ensure we are using
    # a known and approved version of this script.
    file {
        '/usr/local/sbin/puppetsigner.py':
            ensure => present,
            source => 'puppet:///modules/puppetmaster/puppetsigner.py',
            mode   => '0550',
            owner  => 'root',
            group  => 'root'
    }

    cron {
        'puppet_certificate_signer':
            command => '/usr/local/sbin/puppetsigner.py --scriptuser > /dev/null 2>&1',
            require => File['/usr/local/sbin/puppetsigner.py'],
            user    => 'root',
    }

    cron { 'update_public_puppet_repos':
        ensure => present,
        command => '(cd /var/lib/git/operations/puppet && /usr/bin/git pull && /usr/bin/git submodule update --init) > /dev/null 2>&1',
        user => 'gitpuppet',
        environment => 'GIT_SSH=/var/lib/git/ssh',
        minute => '*/1',
    }

    cron { 'update_private_puppet_repos':
        ensure => present,
        command => '(cd /var/lib/git/operations/labs/private && /usr/bin/git pull) > /dev/null 2>&1',
        user => 'gitpuppet',
        environment => 'GIT_SSH=/var/lib/git/ssh',
        minute => '*/1',
    }

    include passwords::openstack::keystone
    $labsstatus_password = $passwords::openstack::keystone::keystone_ldap_user_pass
    $labsstatus_username = 'novaadmin'
    $labsstatus_region = $::site
    $labsstatus_auth_url = 'http://virt1000.wikimedia.org:35357/v2.0'

    file { '/etc/labsstatus.cfg':
        ensure => present,
        content => template('puppetmaster/labsstatus.cfg.erb'),
    }
}
