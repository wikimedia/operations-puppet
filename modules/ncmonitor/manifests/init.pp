# SPDX-License-Identifier: Apache-2.0
# == Class: ncmonitor
# Deployment of ncmonitor configuration, services, and executable
#
# === Parameters
# [*ensure*]
#   If 'present', the module will be configured with all users,
#   files, and services enabled. If 'absent', all of these are
#   removed/disabled.
#
#   Default: 'present'
#
# [*nameservers*]
#   An array of domain names to use as nameservers.
#
#   Default: undef
#
# [*markmon_api_user*]
#   MarkMonitor API username
#
#   Default: undef
#
# [*markmon_api_pass*]
#   MarkMonitor API password
#
#   Default: undef
#
# [*gerrit_ssh_key*]
#   SSH key contents with access to Gerrit.
#
#   Default: undef
#
# [*gerrit_ssh_pubkey*]
#   Corresponding public key to the private key. Only used for
#   convenience of setting up access in services..
#
#   Default: undef
#
# [*http_proxy*]
#   Endpoint to proxy ncmonitor's systemd unit traffic (via
#   Environment=).
#
#   Default: undef

class ncmonitor(
    Wmflib::Ensure            $ensure,
    Array[Stdlib::Host]       $nameservers,
    String                    $markmon_api_user,
    String                    $markmon_api_pass,
    String                    $gerrit_ssh_key,
    Optional[String]          $gerrit_ssh_pubkey,
    Optional[Stdlib::HTTPUrl] $http_proxy,
) {
    $config = {
        acmechief   => {
            conf-path  => 'hieradata/common/certificates.yaml',
            remote-url => 'ssh://ncmonitor@gerrit.wikimedia.org:29418/operations/puppet',
        },
        dnsrepo     => {
            remote-url       => 'ssh://ncmonitor@gerrit.wikimedia.org:29418/operations/dns',
            target-zone-path => 'templates/ncredir-parking',
        },
        gerrit      => {
            reviewers    => [
                'bcornwall@wikimedia.org',
                'cdobbins@wikimedia.org',
                'ffurnari@wikimedia.org',
                'ssingh@wikimedia.org',
                'vgutierrez@wikimedia.org',
            ],
            ssh-key-path => '/etc/ncmonitor/gerrit.key',
        },
        markmonitor => {
            username => $markmon_api_user,
            password => $markmon_api_pass,
        },
        nameservers => $nameservers,
        ncredir     => {
            datfile-path => 'modules/ncredir/files/nc_redirects.dat',
            remote-url   => 'ssh://ncmonitor@gerrit.wikimedia.org:29418/operations/puppet'
        },
    }

    package { 'ncmonitor':
        ensure  => $ensure,
    }

    systemd::sysuser { 'ncmonitor':
        ensure   => $ensure,
        shell    => '/bin/sh',
        home_dir => '/nonexistent',
    }

    $ensure_conf_dir = $ensure ? {
        absent  => $ensure,
        default => 'directory',
    }

    file { '/etc/ncmonitor/':
        ensure => $ensure_conf_dir,
        owner  => 'ncmonitor',
        group  => 'root',
        mode   => '0700',
    }

    file { '/etc/ncmonitor/ncmonitor.yaml':
        ensure    => $ensure,
        owner     => 'ncmonitor',
        group     => 'root',
        mode      => '0400',
        content   => to_yaml($config),
        require   => Package['ncmonitor'],
        backup    => false,
        show_diff => false,
    }

    file { '/etc/ncmonitor/gerrit.key':
        ensure    => $ensure,
        owner     => 'ncmonitor',
        group     => 'root',
        mode      => '0400',
        content   => $gerrit_ssh_key,
        backup    => false,
        show_diff => false,
    }

    if $gerrit_ssh_pubkey {
        file { '/etc/ncmonitor/gerrit.pub':
            ensure  => $ensure,
            owner   => 'ncmonitor',
            group   => 'root',
            mode    => '0644',
            content => $gerrit_ssh_pubkey,
        }
    } else {
        file { '/etc/ncmonitor/gerrit.pub': ensure => 'absent' }
    }

    # Some environments (e.g. WMCS) should not have proxies set. Merely setting
    # a default value for the 'environment' attribute would cause empty
    # Environment= entries to be created. We need to either specify
    # 'environment' with values or not at all.
    $timer_defaults = {
        ensure      => $ensure,
        user        => 'ncmonitor',
        description => 'Verify/Sync non-canonical domains with downstream services',
        command     => '/usr/bin/ncmonitor',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'daily',
        },
        require     => Package['ncmonitor'],
    }

    $timer = $http_proxy? {
        Stdlib::HTTPUrl => {
            'ncmonitor' => {
                environment => {
                    'HTTP_PROXY'  => $http_proxy,
                    'HTTPS_PROXY' => $http_proxy,
                }
            }
        },
        default         => {'ncmonitor' => {}},
    }

    create_resources(systemd::timer::job, $timer, $timer_defaults)

}
