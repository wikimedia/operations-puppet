# Class: puppetmaster::labs
#
# This class handles the Wikimedia Labs specific bits of a Puppetmaster
class puppetmaster::labs {
    package { 'libldap-ruby1.8': ensure => present; }

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

    include passwords::openstack::keystone
    $labsstatus_password = $passwords::openstack::keystone::keystone_ldap_user_pass
    $labsstatus_username = 'novaadmin'
    $labsstatus_region = $::site
    $keystone_host = hiera('labs_keystone_host')
    $labsstatus_auth_url = "${keystone_host}:35357/v2.0'

    file { '/etc/labsstatus.cfg':
        ensure  => present,
        content => template('puppetmaster/labsstatus.cfg.erb'),
    }
}
