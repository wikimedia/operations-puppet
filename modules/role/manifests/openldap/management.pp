# Tools / scripts for helping manage the users in LDAP installation
# Note: This is for the so-called 'labs LDAP', which is used to manage
# both users on labs as well as access control for many things in prod
class role::openldap::management {

    require ::ldap::config::labs
    include passwords::phabricator

    $ldapconfig = $::ldap::config::labs::ldapconfig

    class { '::ldap::management':
        server   => $ldapconfig['servernames'][0],
        basedn   => $ldapconfig['basedn'],
        user     => $ldapconfig['script_user_dn'],
        password => $ldapconfig['script_user_pass'],
    }

    require_package('python-yaml', 'python-ldap', 'python-phabricator')

    file { '/usr/local/bin/cross-validate-accounts':
        ensure => present,
        source => 'puppet:///modules/openldap/cross-validate-accounts.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/bin/offboard-user':
        ensure => present,
        source => 'puppet:///modules/openldap/offboard-user.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    user { 'accountcheck':
        ensure => present,
        system => true,
    }

    $ensure = $::mw_primary ? {
        $::site => 'present',
        default => 'absent',
    }

    cron { 'daily_account_consistency_check':
        ensure  => $ensure,
        require => [ File['/usr/local/bin/cross-validate-accounts'], User['accountcheck']] ,
        command => '/usr/local/bin/cross-validate-accounts',
        user    => 'accountcheck',
        hour    => '4',
        minute  => '0',
    }

    class { '::phabricator::bot':
        username => 'offboarding',
        token    => $passwords::phabricator::offboarding_script_token,
        owner    => 'root',
        group    => 'ops',
    }
}
