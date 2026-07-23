# @summary manage the ssh server daemon and config
# @param listen_ports the ports to listen on
# @param listen_addresses an array of addresses to listen on
# @param permit_root if true allow root logins
# @param authorized_keys_file space seperated list of authorized keys files
# @param authorized_keys_command command to run for authorized keys
# @param authorized_keys_command_user user to run authorized_keys_command as
# @param explicit_macs Allow users to opt out of more secure MACs
# @param enable_kerberos enable kerberos
# @param disable_agent_forwarding disable agent forwarding
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
class ssh::server (
    Array[Stdlib::Port]          $listen_ports                 = [22],
    Array[Stdlib::IP::Address]   $listen_addresses             = [],
    Ssh::Config::PermitRootLogin $permit_root                  = true,
    Array[Stdlib::Unixpath]      $authorized_keys_file         = ['/etc/ssh/userkeys/%u', '/etc/ssh/userkeys/%u.d/cumin'],
    Optional[Stdlib::Unixpath]   $authorized_keys_command      = undef,
    Optional[String[1]]          $authorized_keys_command_user = undef,
    Boolean                      $explicit_macs                = true,
    Boolean                      $enable_kerberos              = false,
    Boolean                      $disable_agent_forwarding     = true,
    Optional[Integer]            $max_sessions                 = undef,
    Optional[String[1]]          $max_startups                 = undef,
    Boolean                      $gateway_ports                = false,
    Array[String[1]]             $accept_env                   = ['LANG', 'LC_*'],
    Array[Ssh::Match]            $match_config                 = [],
    Array[Ssh::KeyType]          $enabled_key_types            = ['rsa', 'ecdsa', 'ed25519'],
    Boolean                      $puppetserver_ca_host_certs   = false,
    Array[String[1]]             $trusted_user_ca_keys         = [],
    Ssh::HostKeys                $host_keys                    = {},
    Ssh::HostCerts               $host_certs                   = {},
    Optional[Stdlib::Unixpath]   $authorized_principals_file   = undef,
) {
    if $puppetserver_ca_host_certs and length($host_certs) > 0 {
        fail('Specify only one of $puppetserver_ca_host_certs or $host_certs')
    }

    if $authorized_keys_command == undef and $authorized_keys_command_user {
        fail('If authorized_keys_command_user is enabled, you also need to configure authorized_keys_command.')
    }

    if $authorized_keys_command and $authorized_keys_command_user == undef {
        fail('If authorized_keys_command is enabled, you also need to configure authorized_keys_command_user.')
    }

    $_permit_root = $permit_root ? {
        String  => $permit_root,
        false   => 'no',
        default => 'yes',
    }

    if length($host_keys) > 0 {
        $key_types = keys($host_keys)
    } else {
        $key_types = $enabled_key_types
    }

    # Starting with Bookworm ChallengeResponseAuthentication is a deprecated
    # alias for KbdInteractiveAuthentication, in older Debian releases
    # KbdInteractiveAuthentication is derived from the config setting for
    # ChallengeResponseAuthentication, so only set it instead.
    if debian::codename::ge('bookworm') {
        $disable_keyboard = 'KbdInteractiveAuthentication no'
    } else {
        $disable_keyboard = 'ChallengeResponseAuthentication no'
    }

    if debian::codename::ge('trixie') {
        $ssh_puppet_conf = '/etc/ssh/sshd_config.d/10-wikimedia-base.conf'
    } else {
        $ssh_puppet_conf = '/etc/ssh/sshd_config'
    }

    # we use the legacy facts here specificaly because we override them in
    # modules/base/lib/facter/interface_primary.rb
    # Although the networking.ip fact now points to a sensible fact
    # networking.ip6 still points to IMO the wrong address.
    # related: https://tickets.puppetlabs.com/browse/FACT-2907
    # related: https://tickets.puppetlabs.com/browse/FACT-2843
    $aliases = [
        $facts['networking']['hostname'],
        $facts['networking']['ip'],
        $facts['networking']['ip6'],
    ].filter |$x| { $x =~ NotUndef }

    if $puppetserver_ca_host_certs {
        if ssh::ssh_ca_key_available() {
            $ssh_ca_key_available = true
            $enabled_key_types.each |Ssh::KeyType $type| {
                ssh::server::ca_signed_hostkey { "/etc/ssh/ssh_host_${type}_key-cert.pub":
                    hosts  => [$facts['networking']['fqdn']] + $aliases,
                    type   => $type,
                    notify => Service['ssh'],
                }
            }
        } else {
            $ssh_ca_key_available = false
            warning('ssh::server: puppetserver_ca_host_certs is true but no CA keys are available')
        }
    }

    if length($trusted_user_ca_keys) > 0 {
        file { '/etc/ssh/trusted_user_ca_keys.pub':
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "${join($trusted_user_ca_keys, "\n")}\n",
        }
    }

    package { 'openssh-server':
        ensure => present,
    }

    service { 'ssh':
        ensure    => running,
        subscribe => File[$ssh_puppet_conf],
    }

    profile::auto_restarts::service { 'ssh': }

    file { '/etc/ssh/userkeys':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => true,
        purge   => true,
    }

    if debian::codename::lt('trixie') {
        # The privilege separation dir for sshd must exist for sshd's
        # config validation command to complete successfully
        file { '/run/sshd':
            ensure => directory,
            mode   => '0755',
        }
    }

    if debian::codename::ge('trixie') {

        unless $puppetserver_ca_host_certs {
            $ssh_ca_key_available = false
        }

        $sshd_params = {
            'listen_ports' => $listen_ports,
            'listen_addresses' => $listen_addresses,
            'permit_root' => $permit_root,
            'authorized_keys_file' => $authorized_keys_file,
            'authorized_keys_command' => $authorized_keys_command,
            'authorized_keys_command_user' => $authorized_keys_command_user,
            'explicit_macs' => $explicit_macs,
            'enable_kerberos' => $enable_kerberos,
            'disable_agent_forwarding' => $disable_agent_forwarding,
            'max_sessions' => $max_sessions,
            'max_startups' => $max_startups,
            'gateway_ports' => $gateway_ports,
            'accept_env' => $accept_env,
            'match_config' => $match_config,
            'puppetserver_ca_host_certs' => $puppetserver_ca_host_certs,
            'trusted_user_ca_keys' => $trusted_user_ca_keys,
            'key_types' => $key_types,
            'host_keys' => $host_keys,
            'host_certs' => $host_certs,
            'authorized_principals_file' => $authorized_principals_file,
            'ssh_ca_key_available' => $ssh_ca_key_available,
        }

        file { $ssh_puppet_conf:
            ensure       => file,
            mode         => '0444',
            content      => epp('ssh/sshd_config-ng.epp', $sshd_params),
            validate_cmd => '/usr/sbin/sshd -t',
        }
    } else {
        file { $ssh_puppet_conf:
            ensure       => file,
            owner        => 'root',
            group        => 'root',
            mode         => '0444',
            content      => template('ssh/sshd_config.erb'),
            validate_cmd => '/usr/sbin/sshd -t -f %',
            require      => Package['openssh-server'],
        }
    }

    if wmflib::have_puppetdb() {
        @@sshkey { $facts['networking']['fqdn']:
            ensure       => present,
            type         => 'ecdsa-sha2-nistp256',
            key          => $facts['ssh']['ecdsa']['key'],
            host_aliases => $aliases,
        }
    }

    $host_keys.each |$type, $key| {
        file { "/etc/ssh/ssh_host_${type}_key":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => "${key}\n",
        }
    }

    if length($host_certs) > 0 {
        if sort(keys($host_certs)) != sort($key_types) {
                fail('Keys for $host_certs and $key_types do not match!')
        }
        $host_certs.each |$type, $key| {
            file { "/etc/ssh/ssh_host_${type}_key-cert.pub":
                ensure  => file,
                owner   => 'root',
                group   => 'root',
                mode    => '0440',
                content => "${key}\n",
            }
        }
    }
}
