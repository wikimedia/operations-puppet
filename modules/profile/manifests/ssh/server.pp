# SPDX-License-Identifier: Apache-2.0
# @summary manage the ssh server daemon and config
# @param listen_ports the ports to listen on
# @param listen_addresses an array of addresses to listen on
# @param permit_root if true allow root logins
# @param authorized_keys_file space seperated list of authorized keys files
# @param lookup_keys_from_ldap if true, user keys will be looked up from ldap
# @param disable_nist_kex Allow uses to temporarily opt out of nist kex disabling
# @param explicit_macs Allow users to opt out of more secure MACs
# @param enable_hba enable host based authentication
# @param enable_kerberos enable kerberos
# @param disable_agent_forwarding disable agent forwarding
# @param challenge_response_auth Disable all password auth
# @param max_sessions allow users to override the maximum number ops sessions
# @param max_startups allow users to override the maximum number ops startups
# @param gateway_ports if true set sshd_config GatewayPorts to yes
# @param accept_env array of elements for AcceptEnv config
# @param match_config a list of additional configs to apply to specific matches.
#                     see Ssh::Match for the data structure
# @param enabled_key_types server key types to enable, if not provided via $host_keys
# @param puppetserver_ca_host_certs if true, puppetserver ca signed host certs will be made available
# @param trusted_user_ca_keys array of trusted user ca keys
# @param host_keys array of ssh host key structs
# @param host_certs array of ssh host cert structs
# @param authorized_principals_file path name to file
# @param authorized_principals array of global principals
class profile::ssh::server (
    Array[Stdlib::Port]          $listen_ports               = lookup('profile::ssh::server::listen_ports'),
    Array[Stdlib::IP::Address]   $listen_addresses           = lookup('profile::ssh::server::listen_addresses'),
    Ssh::Config::PermitRootLogin $permit_root                = lookup('profile::ssh::server::permit_root'),
    Array[Stdlib::Unixpath]      $authorized_keys_file       = lookup('profile::ssh::server::authorized_keys_file'),
    Boolean                      $lookup_keys_from_ldap      = lookup('profile::ssh::server::lookup_keys_from_ldap'),
    Boolean                      $disable_nist_kex           = lookup('profile::ssh::server::disable_nist_kex'),
    Boolean                      $explicit_macs              = lookup('profile::ssh::server::explicit_macs'),
    Boolean                      $enable_hba                 = lookup('profile::ssh::server::enable_hba'),
    Boolean                      $enable_kerberos            = lookup('profile::ssh::server::enable_kerberos'),
    Boolean                      $disable_agent_forwarding   = lookup('profile::ssh::server::disable_agent_forwarding'),
    Boolean                      $challenge_response_auth    = lookup('profile::ssh::server::challenge_response_auth'),
    Optional[Integer]            $max_sessions               = lookup('profile::ssh::server::max_sessions'),
    Optional[String[1]]          $max_startups               = lookup('profile::ssh::server::max_startups'),
    Boolean                      $gateway_ports              = lookup('profile::ssh::server::gateway_ports'),
    Array[String[1]]             $accept_env                 = lookup('profile::ssh::server::accept_env'),
    Array[Ssh::Match]            $match_config               = lookup('profile::ssh::server::match_config'),
    Array[Ssh::KeyType]          $enabled_key_types          = lookup('profile::ssh::server::enabled_key_types'),
    Boolean                      $puppetserver_ca_host_certs = lookup('profile::ssh::server::puppetserver_ca_host_certs'),
    Array[String[1]]             $trusted_user_ca_keys       = lookup('profile::ssh::server::trusted_user_ca_keys', { 'default_value' => [] }),
    Ssh::HostKeys                $host_keys                  = lookup('profile::ssh::server::host_keys', { 'default_value' => {} }),
    Ssh::HostCerts               $host_certs                 = lookup('profile::ssh::server::host_certs', { 'default_value' => {} }),
    Optional[Stdlib::Unixpath]   $authorized_principals_file = lookup('profile::ssh::server::authorized_principals_file', { 'default_value' => undef }),
    Array[String[1]]             $authorized_principals      = lookup('profile::ssh::server::authorized_principals', { 'default_value' => [] }),
) {
    if $lookup_keys_from_ldap {
        if debian::codename::ge('buster') {
            ensure_packages(['python3-ldap'])
        } else {
            ensure_packages(['python3-pyldap'])
        }

        # The 'ssh-key-ldap-lookup' tool is called during login ssh via AuthorizedKeysCommand.  It
        #  returns public keys from ldap for the specified username.
        # It is in /usr/sbin and not /usr/local/sbin because on Debian /usr/local is 0775
        # and sshd refuses to use anything under /usr/local because of the permissive group
        # permission there (and group is set to 'staff', slightly different from root).
        # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=538392
        file { '/usr/sbin/ssh-key-ldap-lookup':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/profile/ssh/server/ssh-key-ldap-lookup.py',
        }

        # For security purposes, sshd will only run ssh-key-ldap-lookup as the 'ssh-key-ldap-lookup' user.
        user { 'ssh-key-ldap-lookup':
            ensure => present,
            system => true,
            home   => '/nonexistent', # Since things seem to check for $HOME/.whatever unconditionally...
            shell  => '/bin/false',
        }

        $authorized_keys_command = '/usr/sbin/ssh-key-ldap-lookup'
        $authorized_keys_command_user = 'ssh-key-ldap-lookup'
    } else {
        $authorized_keys_command = undef
        $authorized_keys_command_user = undef
    }

    if length($authorized_principals) > 0 and $authorized_principals_file {
        file { $authorized_principals_file :
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "${join($authorized_principals, "\n")}\n",
        }
    }

    class {'ssh::server':
        *                            => wmflib::resource::filter_params(
                                          'lookup_keys_from_ldap',
                                          'authorized_principals'
                                        ),
        authorized_keys_command      => $authorized_keys_command,
        authorized_keys_command_user => $authorized_keys_command_user,
    }
}
