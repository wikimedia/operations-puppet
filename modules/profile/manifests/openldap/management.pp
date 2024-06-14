# SPDX-License-Identifier: Apache-2.0
# == Class profile::openldap::management
#
# Tools / scripts for helping manage the users in LDAP installation
# Note: This is for the so-called 'labs LDAP', which is used to manage
# both users on labs as well as access control for many things in prod
#
# === Parameters
#
# [*timer_active*] Whether to activate the daily account consistency check or not.
#
class profile::openldap::management(
    Hash    $ldap         = lookup('ldap'),
    Boolean $timer_active = lookup('profile::openldap::management::timer_active'),
) {
    include profile::ldap::bitu
    include profile::openldap::client
    include passwords::phabricator

    class { 'ldap::management':
        server   => $ldap['rw-server'],
        basedn   => $ldap['base-dn'],
        user     => $ldap['script_user_dn'],
        password => $ldap['script_user_pass'],
    }

    if debian::codename::ge('bookworm') {
        ensure_packages(['python3-yaml', 'python3-ldap', 'python3-phabricator'])
    } else {
        ensure_packages([
            'python-yaml', 'python-ldap',
            'python3-yaml', 'python3-ldap', 'python3-phabricator',
        ])
    }

    file { '/usr/local/bin/cross-validate-accounts':
        ensure => present,
        source => 'puppet:///modules/openldap/cross-validate-accounts.py',
        mode   => '0555',
    }

    file { '/usr/local/bin/offboard-user':
        ensure => present,
        source => 'puppet:///modules/openldap/offboard-user.py',
        mode   => '0555',
    }

    if debian::codename::ge('bookworm') {
        systemd::sysuser { 'accountcheck': }
    } else {
        user { 'accountcheck':
            ensure => present,
            system => true,
        }
    }

    $ensure = $timer_active ? {
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
    }

    class { 'phabricator::bot':
        username => 'offboarding',
        token    => $passwords::phabricator::offboarding_script_token,
        owner    => 'root',
        group    => 'ops',
    }
}
