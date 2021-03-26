# @summary manage the ssh server daemon and config
# @param listen_port the port to listen on
# @param listen_address the address to listen on
# @param permit_root if true allow root logins
# @param authorized_keys_file space seperated list of authorized keys files
# @param authorized_keys_command command to run for authorized keys
# @param disable_nist_kex Allow uses to temporarily opt out of nist kex disabling
# @param explicit_macs Allow users to opt out of more secure MACs
# @param enable_hba enable host based authentication
# @param enable_kerberos enable kerberos
# @param disable_agent_forwarding disable agent forwarding
# @param challenge_response_auth Disable all password auth
# @param max_sessions allow users to override the maximum number ops sessions
# @param max_startups allow users to override the maximum number ops startups
class ssh::server (
    # TODO convert to Stdlib::Port
    String                     $listen_port              = '22',
    Optional[Stdlib::Host]     $listen_address           = undef,
    Boolean                    $permit_root              = true,
    # TODO convert to Array[Stdlib::Unuxpath]
    Optional[String]           $authorized_keys_file     = undef,
    Stdlib::Unixpath           $authorized_keys_command  = '/usr/sbin/ssh-key-ldap-lookup',
    Boolean                    $disable_nist_kex         = true,
    Boolean                    $explicit_macs            = true,
    Boolean                    $enable_hba               = false,
    Boolean                    $enable_kerberos          = false,
    Boolean                    $disable_agent_forwarding = true,
    Boolean                    $challenge_response_auth  = true,
    Optional[Integer]          $max_sessions             = undef,
    Optional[Integer]          $max_startups             = undef,
) {
    package { 'openssh-server':
        ensure => present,
    }

    service { 'ssh':
        ensure    => running,
        subscribe => File['/etc/ssh/sshd_config'],
    }

    base::service_auto_restart { 'ssh': }
    # TODO just make this the param default
    $_authorized_keys_file = pick($authorized_keys_file, '/etc/ssh/userkeys/%u /etc/ssh/userkeys/%u.d/cumin')

    file { '/etc/ssh/userkeys':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => true,
        purge   => true,
    }

    file { '/etc/ssh/sshd_config':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ssh/sshd_config.erb'),
        require => Package['openssh-server'],
    }

    $aliases = [
        $facts['networking']['hostname'],
        $facts['networking']['ip'],
        $facts['networking']['ip6'],
    ].filter |$x| { $x =~ NotUndef }

    @@sshkey { $facts['networking']['fqdn']:
        ensure       => present,
        type         => 'ecdsa-sha2-nistp256',
        key          => $facts['ssh']['ecdsa']['key'],
        host_aliases => $aliases,
    }
}
