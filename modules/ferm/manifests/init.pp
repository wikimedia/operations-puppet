# ferm is a frontend for iptables
# https://wiki.debian.org/ferm
# @param ensure ensure parameter
class ferm (
    Wmflib::Ensure $ensure ='present'
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
            # This is a bit of an abuse of the puppet DSL
            # We use the status command to ensure that the rules on disk match the rules loaded in the
            # kernel; if not we want to reload the rule base
            status  => '/usr/local/sbin/ferm-status',
            # When the service status command fails, puppet sets the service status to stopped:
            # https://github.com/puppetlabs/puppet/blob/main/lib/puppet/provider/service/base.rb#L77
            # which means that it calls the startcmd (not restartcmd). As such we need to update the start command
            # so that it calls systemd reload instead of systemd restart.  However we also need to account for
            # when the service is actually stopped which is why we use reload-or-restart.
            start   => '/bin/systemctl reload-or-restart ferm',
            require => [
                Package['ferm'],
                File['/usr/local/sbin/ferm-status'],
            ],
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
