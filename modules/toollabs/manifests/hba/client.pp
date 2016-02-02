# Class: toollabs::hba::client
#
# This class configures an instance to enable outgoing ssh connections
# with host-based authentication.
class toollabs::hba::client {
    file_line { 'ssh_config_hostbasedauthentication':
        ensure => present,
        path   => '/etc/ssh/ssh_config',
        line   => 'HostbasedAuthentication yes',
        match  => '^ *HostbasedAuthentication\b',
    }

    file_line { 'ssh_config_enablesshkeysign':
        ensure => present,
        path   => '/etc/ssh/ssh_config',
        line   => 'EnableSSHKeysign yes',
        match  => '^ *EnableSSHKeysign\b',
    }
}
