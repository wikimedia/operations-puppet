# == Class: mediawiki::cgroup
#
# MediaWiki uses cgroups (abbreviated from control groups) to limit the
# resource usage of commands invoked in a subprocess via wfShellExec(),
# like texvc and lilypond. The cgroup is specified by via $wgShellCgroup.
#
# See also:
# * <https://www.mediawiki.org/wiki/Manual:$wgShellCgroup>
# * <https://github.com/wikimedia/mediawiki-core/blob/master/includes/limit.sh>
# * <https://www.kernel.org/doc/Documentation/cgroups/cgroups.txt>
#
class mediawiki::cgroup {
    package { 'cgroup-bin':
        ensure => present,
    }

    file { '/etc/init/mw-cgroup.conf':
        source  => 'puppet:///modules/mediawiki/cgroup/mw-cgroup.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['cgroup-bin'],
        notify  => Service['mw-cgroup'],
    }

    service { 'mw-cgroup':
        ensure   => running,
        provider => 'upstart',
        require  => File['/etc/init/mw-cgroup.conf'],
    }

    # The cgroup-mediawiki-clean script is used as the release_agent
    # script for the cgroup. When the last task in the cgroup exits,
    # the kernel will run the script.

    file { '/usr/local/bin/cgroup-mediawiki-clean':
        source => 'puppet:///modules/mediawiki/cgroup/cgroup-mediawiki-clean',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
