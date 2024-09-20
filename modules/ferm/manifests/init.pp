# ferm is a frontend for iptables
# https://wiki.debian.org/ferm
# @param ensure ensure parameter
class ferm (
    Wmflib::Ensure $ensure = 'present',
) {
    # @resolve requires libnet-dns-perl
    ensure_packages('libnet-dns-perl')
    package {'iptables':
        ensure => stdlib::ensure($ensure, package),
    }

    if $ensure == 'present' {
        ensure_packages('ferm')
    } elsif $ensure == 'absent' {
        ensure_packages(['ferm'], {'ensure' => 'purged'})
    }

    if !$facts['wmflib']['is_container'] {
        file { '/etc/modprobe.d/nf_conntrack.conf':
            ensure => stdlib::ensure($ensure, 'file'),
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/firewall/nf_conntrack.conf',
        }

        # The nf_conntrack kernel module is usually auto-loaded during ferm startup.
        # But some additional configuration options for timewait handling are configured
        #   via sysctl settings and if ferm autoloads the kernel module after
        #   systemd-sysctl.service has run, the sysctl settings are not applied.
        # Add the nf_conntrack module via /etc/modules-load.d/ which loads
        #   them before systemd-sysctl.service is executed.
        file { '/etc/modules-load.d/conntrack.conf':
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "nf_conntrack\n",
            require => File['/etc/modprobe.d/nf_conntrack.conf'],
            before  => Package['ferm', 'libnet-dns-perl', 'conntrack'],
        }
    }

    file { '/usr/local/sbin/ferm-status':
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0550',
        owner   => 'root',
        group   => 'root',
        content => file('ferm/ferm_status.py'),
    }

    file { '/etc/ferm' :
        ensure => stdlib::ensure($ensure, 'directory'),
        force  => true,
        mode   => '2751',
        group  => 'adm',
    }

    if $ensure == 'present' {
        service { 'ferm':
            ensure  => running,
            # When restartcmd ('systemctl restart') is called it will call the ferm init script with stop and start sequentially.
            # This does flush all(!) rules before reapplying them, so we use reload-or-restart here as well to prevent this.
            # Note that start,reload,restart,force-reload are all handled by the same ferm init script (apart from different
            # log messages).
            restart => '/bin/systemctl reload-or-restart ferm',
        }
        systemd::override { 'ferm-service-status-restart':
            unit   => 'ferm',
            source => 'puppet:///modules/ferm/ferm_systemd_override',
        }

        file { '/etc/ferm/ferm.conf':
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            source  => 'puppet:///modules/ferm/ferm.conf',
            require => Package['ferm'],
            notify  => Service['ferm'],
        }

        file { '/etc/ferm/functions.conf' :
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            source  => 'puppet:///modules/ferm/functions.conf',
            require => Package['ferm'],
            notify  => Service['ferm'],
        }

        file { '/etc/ferm/conf.d' :
            ensure  => stdlib::ensure($ensure, 'directory'),
            owner   => 'root',
            group   => 'adm',
            mode    => '0551',
            recurse => true,
            purge   => true,
            force   => true,
            require => Package['ferm'],
            notify  => Service['ferm'],
        }

        file { '/etc/default/ferm' :
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            source  => 'puppet:///modules/ferm/ferm.default',
            require => Package['ferm'],
            notify  => Service['ferm'],
        }
    }

    # Starting with Bullseye iptables default to the nft backend, but for ferm
    # we need the legacy backend
    if debian::codename::ge('bullseye') and $ensure == 'present' {
        alternatives::select { 'iptables':
            path    => '/usr/sbin/iptables-legacy',
            require => Package['iptables'],
        }

        alternatives::select { 'ip6tables':
            path    => '/usr/sbin/ip6tables-legacy',
            require => Package['iptables'],
        }
    }

    # the rules are virtual resources for cases where they are defined in a
    # class but the host doesn't have the ferm class included
    File <| tag == 'ferm' |>
}
