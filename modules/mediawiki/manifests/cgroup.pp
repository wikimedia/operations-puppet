# == Class: mediawiki::cgroup
#
# MediaWiki uses cgroups (abbreviated from control groups) to limit the
# resource usage of commands invoked in a subprocess via wfShellExec(),
# like texvc and lilypond. The cgroup is specified by via $wgShellCgroup.
#
# See also: <https://www.mediawiki.org/wiki/Manual:$wgShellCgroup>
#
class mediawiki::cgroup {

    require_package 'cgroup-bin'

    # The cgroup-mediawiki-clean script is used as the release_agent
    # script for the cgroup. When the last task in the cgroup exits,
    # the kernel will run the script.

    file { '/usr/local/bin/cgroup-mediawiki-clean':
        source => 'puppet:///modules/mediawiki/cgroup/cgroup-mediawiki-clean',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    base::service_unit { 'mw-cgroup':
        ensure  => present,
        systemd => true,
        upstart => true,
        refresh => false,
    }

}
