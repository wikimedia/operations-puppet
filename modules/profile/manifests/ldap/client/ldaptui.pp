# SPDX-License-Identifier: Apache-2.0
# = Class: profile::ldap::client::ldaptui
#
# This installs a basic LDAP terminal UI for creating
# editing and resetting of passwords.
#
class profile::ldap::client::ldaptui(
    Hash   $ldap_config    = lookup('ldap'),
    String $ldap_user      = lookup('profile::openstack::base::ldap_user_dn'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
) {
    ensure_packages(['python3-venv'])
    $ldap_rw_host = $ldap_config['rw-server']
    $base_dir = '/srv/ldaptui'
    $venv_path = "${base_dir}/.venv"

    file { $base_dir:
        ensure =>  directory
    }

    file { '/etc/ldaptui':
        ensure =>  directory
    }

    file { '/usr/local/bin/ldaptui':
        mode   => '0550',
        source => 'puppet:///modules/profile/ldap/client/ldaptui.sh'
    }

    file { '/etc/ldaptui/config.json':
        mode    => '0400',
        content => template('profile/ldap/client/ldaptui.config.json.erb')
    }

    file { "${base_dir}/requirements.txt":
        source => 'puppet:///modules/profile/ldap/client/ldaptui/requirements.txt'
    }

    file { "${base_dir}/ldaptui.py":
        source => 'puppet:///modules/profile/ldap/client/ldaptui/ldaptui.py'
    }

    exec { 'ldaptui-venv':
        command => "/usr/bin/python3 -m venv ${venv_path}",
        creates => $venv_path,
        notify  => Exec['ldaptui install deps'],
    }

    exec { 'ldaptui install deps':
        command     => "${venv_path}/bin/pip install -r ${base_dir}/requirements.txt",
        refreshonly => true
    }
}
