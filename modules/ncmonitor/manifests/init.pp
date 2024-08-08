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
# [*acmechief_conf_path*]
#   Relative path from the base of the acme-chief repo to the certificate
#   configuration.
#
#   Default: undef
#
# [*acmechief_remote_url*]
#   Git remote URL to the upstream repository.
#
#   Default: undef
#
# [*dnsrepo_remote_url*]
#   Git remote URL to the upstream repository.
#
#   Default: undef
#
# [*dnsrepo_target_zone_path*]
#   Relative path from the base of the dns repo to the symlink target
#
#   Default: undef
#
# [*gerrit_ssh_key*]
#   SSH key contents with access to Gerrit.
#
#   Default: undef
#
# [*gerrit_ssh_key_path*]
#   Filesystem path to the SSH private key.
#
#   Default: undef
#
# [*gerrit_ssh_pubkey*]
#   Corresponding public key to the private key. Only used for
#   convenience of setting up access in services.
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
# [*markmon_ignored_domains*]
#   List of MarkMonitor domains to ignore completely
#
#   Default: undef
#
# [*nameservers*]
#   An array of domain names to use as nameservers.
#
#   Default: undef
#
# [*ncredir_datfile_path*]
#   Relative path from the base of the ncredir repo to the redirects datfile.
#
#   Default: undef
#
# [*ncredir_remote_url*]
#   Git remote URL to the upstream repository.
#
#   Default: undef
#
# [*reviewers*]
#   List of email addresses corresponding to those that will review the changes.
#
#   Default: undef
#
# [*suffix_list_path*]
#   Filesystem path to the data file containing all TLDs.
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
    String                    $acmechief_conf_path,
    String                    $acmechief_remote_url,
    String                    $dnsrepo_remote_url,
    String                    $dnsrepo_target_zone_path,
    String                    $gerrit_ssh_key,
    String                    $gerrit_ssh_key_path,
    String                    $markmon_api_user,
    String                    $markmon_api_pass,
    Array[Stdlib::Fqdn]       $markmon_ignored_domains,
    Array[Stdlib::Host]       $nameservers,
    String                    $ncredir_datfile_path,
    String                    $ncredir_remote_url,
    Array[String]             $reviewers,
    Stdlib::Absolutepath      $suffix_list_path,
    Optional[String]          $gerrit_ssh_pubkey,
    Optional[Stdlib::HTTPUrl] $http_proxy,
) {
    $config = {
        acmechief        => {
            conf-path  => $acmechief_conf_path,
            remote-url => $acmechief_remote_url,
        },
        dnsrepo          => {
            remote-url       => $dnsrepo_remote_url,
            target-zone-path => $dnsrepo_target_zone_path,
        },
        gerrit           => {
            reviewers    => $reviewers,
            ssh-key-path => $gerrit_ssh_key_path,
        },
        markmonitor      => {
            username        => $markmon_api_user,
            password        => $markmon_api_pass,
            ignored-domains => $markmon_ignored_domains,
        },
        nameservers      => $nameservers,
        ncredir          => {
            datfile-path => $ncredir_datfile_path,
            remote-url   => $ncredir_remote_url,
        },
        suffix-list-path => $suffix_list_path,
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

    file { $gerrit_ssh_key_path:
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
        command     => '/usr/bin/ncmonitor --email-ns-issues --submit-patch',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'monthly',
        },
        require     => Package['ncmonitor'],
        path_exists => $suffix_list_path,
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
