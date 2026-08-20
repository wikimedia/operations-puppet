# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure base config
# @param overlayfs if to use overlays
# @param wikimedia_clusters the wikimedia clusters
# @param cluster the cluster
# @param enable_contacts use the contacts module
# @param core_dump_pattern the core dump pattern
# @param unprivileged_userns_clone enable kernel.unprivileged_userns_clone
# @param additional_purged_packages A list of additional packages to purge
# @param manage_resolvconf set this to false to disable managing resolv.conf
#   useful in container environments
# @param rp_filter. This variable is overloaded for backwards compatibility purposes.
#   By default it is set to true, set this to false to disable rp_filtering. However you can also pass a hash with 2 keys:
#   all_rp_filter and default_rp_filter which allows you to configure those with any of the 3 possible values individually
# @param no_cron If enabled, don't depend on the presence of a cron daemon. In a standard installation
#                we still have common packages which depend on a cron-compatible daemon, but there are
#                already use cases in Cloud VPS where cron isn't necessary. With increased adoption of
#                systemd timers, this might also be applicable for a future baremetal installation.
#                For now this option only omits the automated service restarts for cron.
# @param use_linux612_on_bookworm install the linux 6.12 kernel from backports on Bookworm.
# @param use_linux_from_bpo_on_trixie install the linux 6.16+ kernel from backports on Trixie.
class profile::base (
    Hash                                $wikimedia_clusters                 = lookup('wikimedia_clusters'),
    String                              $cluster                            = lookup('cluster'),
    Boolean                             $overlayfs                          = lookup('profile::base::overlayfs'),
    Boolean                             $enable_contacts                    = lookup('profile::base::enable_contacts'),
    String                              $core_dump_pattern                  = lookup('profile::base::core_dump_pattern'),
    Boolean                             $unprivileged_userns_clone          = lookup('profile::base::unprivileged_userns_clone'),
    Boolean                             $remove_python2_on_bullseye         = lookup('profile::base::remove_python2_on_bullseye', {'default_value' => true}),
    Boolean                             $manage_resolvconf                  = lookup('profile::base::manage_resolvconf', {'default_value' => true}),
    Array[String[1]]                    $additional_purged_packages         = lookup('profile::base::additional_purged_packages'),
    Variant[Boolean, Hash]              $rp_filter                          = lookup('profile::base::enable_rp_filter', {'default_value' => true}),
    Boolean                             $no_cron                            = lookup('profile::base::no_cron', {'default_value' => false}),
    Boolean                             $use_linux612_on_bookworm           = lookup('profile::base::use_linux612_on_bookworm', {'default_value' => false}),
    Boolean                             $use_linux_from_bpo_on_trixie       = lookup('profile::base::use_linux_from_bpo_on_trixie', {'default_value' => false}),
    Boolean                             $tighten_ptrace                     = lookup('profile::base::tighten_ptrace', {'default_value' => false}),
) {
    # Sanity checks for cluster - T234232
    if ! has_key($wikimedia_clusters, $cluster) {
        fail("Cluster ${cluster} not defined in wikimedia_clusters")
    }

    # create standard directories
    # perform this here and early to avoid dependency cycles
    file { ['/usr/local/sbin', '/usr/local/share/bash']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    include profile::adduser
    contain profile::puppet::agent
    contain profile::base::certificates
    include profile::apt
    if !$facts['wmflib']['is_container'] and $manage_resolvconf {
        include profile::systemd::timesyncd
    }
    unless $facts['wmflib']['is_container']  {
        class { 'grub::defaults': }
    }

    if $use_linux612_on_bookworm {
        # We need to explicitly list the linux-base's version since the package
        # is already installed when puppet runs, and without a specific
        # pinned version we ended up in linux-image refusing to install
        # because of linux-base not being installed with its expected version.
        apt::package_from_bpo { 'linux-6.12-bookworm':
            packages => {
                'linux-base'                       => '4.12.1~bpo12+1',
                'linux-image-6.12.101+deb12-amd64' => 'present',
            },
            distro   => 'bookworm',
        }
    }

    # Only used by ML's big GPU machines at the moment (20260729)
    if $use_linux_from_bpo_on_trixie {
        apt::package_from_bpo { 'linux-6.19-trixie':
            packages => {
                'linux-image-6.19.14+deb13-amd64' => 'present',
            },
            distro   => 'trixie',
        }
    }

    include passwords::root
    include network::constants
    if $manage_resolvconf {
        include profile::resolving
    }
    include profile::mail::default_mail_relay

    include profile::logrotate
    include profile::prometheus::node_exporter
    include profile::rsyslog
    include profile::syslog::remote
    include profile::prometheus::rsyslog_exporter
    include profile::prometheus::cadvisor
    include profile::prometheus::ethtool_exporter

    if !$facts['wmflib']['is_container'] {
        # If passed a Boolean, we know that we either want it consistent across all settings.
        if $rp_filter.is_a(Boolean) {
            $default_rp_filter = bool2num($rp_filter)
            $all_rp_filter = $default_rp_filter
            # But if we are passed a struct, then we know the caller has specific needs,
            # honor them without breaking backwards compatibility
        } elsif $rp_filter.is_a(Hash) {
            $default_rp_filter = $rp_filter['default_rp_filter']
            $all_rp_filter = $rp_filter['all_rp_filter']
        } else {
            fail('rp_filter is not a Boolean or Hash, bailing out')
        }
        # TODO: make base::sysctl a profile itself?
        class { 'base::sysctl':
            unprivileged_userns_clone => $unprivileged_userns_clone,
            default_rp_filter         => $default_rp_filter,
            all_rp_filter             => $all_rp_filter
        }
    }
    class { 'motd': }
    # Indicate if any services need to be restarted
    motd::script { 'Check for restarts':
        priority => 99,
        source   => 'puppet:///modules/profile/motd/check_restarts.sh',
    }
    class { 'base::standard_packages':
        remove_python2             => $remove_python2_on_bullseye,
        additional_purged_packages => $additional_purged_packages,
        no_cron                    => $no_cron,
    }

    class { 'acct':
        # In Trixie and older the package depends on Cron to manage
        # log rotation. In Forky and newer, the package will ship its
        # own logrotate configuration, so we can rely on that instead
        # of shipping our own.
        manage_logrotate => $no_cron and debian::codename::le('trixie'),
    }

    include profile::environment
    class { 'base::sysctl::core_dumps':
        core_dump_pattern => $core_dump_pattern,
    }

    include profile::ssh::client
    include profile::ssh::server

    if !$facts['wmflib']['is_container'] {
        class { 'base::kernel':
            overlayfs => $overlayfs,
        }
    }

    include profile::debdeploy::client

    class { 'base::initramfs': }
    include profile::auto_restarts

    class { 'prometheus::node_debian_version': }
    class { 'prometheus::node_dpkg_success': }
}
