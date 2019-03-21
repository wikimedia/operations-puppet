class ssh::server (
    $listen_port = '22',
    $listen_address = undef,
    $permit_root = true,
    $authorized_keys_file = undef,
    $authorized_keys_command = '/usr/sbin/ssh-key-ldap-lookup',
    $disable_nist_kex = true, # Allow labs projects to temporarily opt out of nist kex disabling
    $explicit_macs = true, # Allow labs projects to temporarily opt out of more secure MACs
    $enable_hba = false,
    $disable_agent_forwarding = true,
    $challenge_response_auth = true,  # Disable all password auth in labs, we don't use 2fa there
    $max_sessions = undef,  # Allow Cloud VPS restricted bastions to override it for Cumin
    $max_startups = undef,  # Allow Cloud VPS restricted bastions to override it for Cumin
) {
    package { 'openssh-server':
        ensure => present,
    }

    service { 'ssh':
        ensure    => running,
        subscribe => File['/etc/ssh/sshd_config'],
    }

    base::service_auto_restart { 'ssh': }

    if $authorized_keys_file {
        $ssh_authorized_keys_file = $authorized_keys_file
    } else {
        $ssh_authorized_keys_file ='/etc/ssh/userkeys/%u /etc/ssh/userkeys/%u.d/cumin'
    }

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

    # publish this hosts's host key; prefer ECDSA -> RSA (no DSA)
    #
    # Puppet sshkey hardcodes acceptable types in its code, and ed25519 is not
    # a valid type in trusty's version (3.4.3). It is in jessie's version
    # (3.7.3), though. So this is waiting until trusty is gone, or until we
    # backport a newer version of puppet to trusty.

    if $::sshecdsakey {
        # facter bug: one key regardless of ECDSA keytype;
        # no type exported as a separate variable
        $key  = $::sshecdsakey
        $type = 'ecdsa-sha2-nistp256'
    } elsif $::sshrsakey {
        $key  = $::sshrsakey
        $type = 'ssh-rsa'
    } else {
        err("No valid SSH host key found for ${::fqdn}")
    }

    if $::ipaddress6 == undef {
        $aliases = [ $::hostname, $::ipaddress ]
    } else {
        $aliases = [ $::hostname, $::ipaddress, $::ipaddress6 ]
    }

    debug("Storing ${type} SSH hostkey for ${::fqdn}")
    @@sshkey { $::fqdn:
        ensure       => present,
        type         => $type,
        key          => $key,
        host_aliases => $aliases,
    }
}
