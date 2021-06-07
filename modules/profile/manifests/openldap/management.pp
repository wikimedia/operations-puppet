# == Class profile::openldap::management
#
# Tools / scripts for helping manage the users in LDAP installation
# Note: This is for the so-called 'labs LDAP', which is used to manage
# both users on labs as well as access control for many things in prod
#
# === Parameters
#
# [*cron_active*] Whether to activate the daily account consistency check or not.
#
class profile::openldap::management(
    Boolean $cron_active         = lookup('profile::openldap::management::cron_active'),
    Hash $production_ldap_config = lookup('ldap', Hash, hash, {}),
) {
    require ::profile::ldap::client::labs
    include passwords::phabricator

    $ldapconfig = $::ldap::config::labs::ldapconfig

    class { '::ldap::management':
        server   => $production_ldap_config['rw-server'],
        basedn   => $production_ldap_config['base-dn'],
        user     => $ldapconfig['script_user_dn'],
        password => $ldapconfig['script_user_pass'],
    }

    ensure_packages([
        'python-yaml', 'python-ldap',
        'python3-yaml', 'python3-ldap', 'python3-phabricator',
    ])

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

    $ensure = $cron_active ? {
        true => present,
        default => absent
    }
    systemd::timer::job { 'daily_account_consistency_check':
        ensure        => $ensure,
        description   => 'Daily account consistency check',
        command       => '/usr/local/bin/cross-validate-accounts',
        interval      => {'start' => 'OnCalendar', 'interval' => 'Mon..Fri 04:00'},
        user          => 'accountcheck',
        send_mail     => true,
        ignore_errors => true,
        require       => [ File['/usr/local/bin/cross-validate-accounts'], User['accountcheck']],
    }

    class { '::phabricator::bot':
        username => 'offboarding',
        token    => $passwords::phabricator::offboarding_script_token,
        owner    => 'root',
        group    => 'ops',
    }
}
