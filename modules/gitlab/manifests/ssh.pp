# SPDX-License-Identifier: Apache-2.0
# @summary configuer gitlab ssh daemon
# @param ssh_listen_addresses the addresses to listen on
# @param ssh_port the port to listen on
class gitlab::ssh (
    Wmflib::Ensure             $ensure               = 'present',
    Array[Stdlib::IP::Address] $ssh_listen_addresses = ['127.0.0.1', '::1'],
    Stdlib::Port               $listen_port          = 22,
    Stdlib::Unixpath           $base_dir             = '/etc/ssh-gitlab',
    String                     $syslog_facility      = 'AUTH',
    String                     $syslog_level         = 'VERBOSE',
    Integer[1]                 $login_grace_time     = 60,
    String                     $max_start_ups        = '10:30:60',
    Integer[1]                 $max_sessions         = 10,
    Integer[1]                 $max_auth_tries       = 3,
    Array[String]              $accept_env           = ['LANG', 'LC_*'],
    Array[String]              $host_key_algos       = ['ecdsa', 'ed25519', 'rsa'],
    Array[String]              $kex_algorithms       = ['curve25519-sha256@libssh.org', 'diffie-hellman-group-exchange-sha256'],
    Array[String]              $sshd_options         = [],
    Array[String]              $ciphers              = [
        'chacha20-poly1305@openssh.com', 'aes256-gcm@openssh.com', 'aes128-gcm@openssh.com',
        'aes256-ctr', 'aes192-ctr', 'aes128-ctr',
    ],
    Array[String]              $macs                 = [
        'hmac-sha2-512-etm@openssh.com', 'hmac-sha2-256-etm@openssh.com', 'umac-128-etm@openssh.com',
        'hmac-sha2-512', 'hmac-sha2-256', 'umac-128@openssh.com',
    ],
    Boolean                    $manage_host_keys     = false,
    Stdlib::Host               $gitlab_domain        = 'gitlab.wikimedia.org',
) {
    $config_file = "${base_dir}/sshd_gitlab"

    file { $base_dir:
        ensure  => stdlib::ensure($ensure, 'directory'),
        recurse => $ensure == 'absent',
        force   => true,
        owner   => root,
        mode    => '0755',
    }

    if $manage_host_keys {
        $host_key_algos.each |$type| {
            ['public', 'private'].each |$privacy| {
                if $privacy == 'public' {
                    $ext = '.pub'
                    $mode = '0644'
                } else {
                    $ext = ''
                    $mode = '0600'
                }
                $filename = "ssh_host_${type}_key${ext}"
                file { "${base_dir}/${filename}" :
                    ensure  => stdlib::ensure($ensure, 'file'),
                    owner   => root,
                    group   => root,
                    mode    => $mode,
                    content => secret("gitlab/${filename}"),
                    notify  => Service['ssh-gitlab'],
                }

                if $privacy == 'public' and $type == 'ecdsa' {
                    # add public key to make it available as in wmf known hosts
                    # TODO: use name instead of host_aliases with puppet 7
                    # https://github.com/puppetlabs/puppetlabs-sshkeys_core/pull/27
                    # The key type is set in the secret content already.
                    @@sshkey { $gitlab_domain:
                        ensure       => $ensure,
                        key          => secret("gitlab/${filename}"),
                        host_aliases => dnsquery::lookup($gitlab_domain, true),
                    }
                }
            }
        }
    } elsif $ensure == 'present' {
        $host_key_algos.each |$algo| {
            $host_key_file = "${base_dir}/ssh_host_${algo}_key"
            exec { "generate gitlab ssh host key(${algo})":
                command => "/usr/bin/ssh-keygen -q -N '' -t ${algo} -f ${host_key_file}",
                creates => $host_key_file,
                require => File[$base_dir],
            }
        }
    }

    file { "${base_dir}/moduli":
        ensure => stdlib::ensure($ensure, 'file'),
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'file:///etc/ssh/moduli',
    }
    file { $config_file:
        ensure       => $ensure,
        owner        => root,
        group        => root,
        mode         => '0440',
        content      => template('gitlab/sshd_config.erb'),
        validate_cmd => '/usr/sbin/sshd -t -f %',
        notify       => Service['ssh-gitlab'],
    }

    systemd::service { 'ssh-gitlab':
        ensure         => $ensure,
        content        => template('gitlab/sshd.service.erb'),
        service_params => { 'restart' => 'systemctl reload sshd-gitlab' },
    }

    profile::auto_restarts::service { 'ssh-gitlab': }
}
