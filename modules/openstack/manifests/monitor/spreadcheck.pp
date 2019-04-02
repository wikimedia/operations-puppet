# == Class: openstack::monitor::spreadcheck
# NRPE check to see if critical instances for a project
# are spread out enough among the labvirt* hosts
class openstack::monitor::spreadcheck(
    $active,
) {
    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # Script that checks how 'spread out' critical instances for a project
    # are. See T101635
    file { '/usr/local/sbin/wmcs-spreadcheck':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/monitor/wmcs-spreadcheck.py',
    }

    ['tools', 'deployment-prep'].each |String $project| {
        file { "/etc/wmcs-spreadcheck-${project}.yaml":
            ensure => $ensure,
            owner  => 'nagios',
            group  => 'nagios',
            mode   => '0400',
            source => "puppet:///modules/openstack/monitor/wmcs-spreadcheck-${project}.yaml",
        }
        nrpe::monitor_service { "check-${project}-spread":
            ensure       => $ensure,
            nrpe_command => "/usr/local/sbin/wmcs-spreadcheck --config /etc/wmcs-spreadcheck-${project}.yaml",
            description  => "${project} project instance distribution",
            require      => File[
                '/usr/local/sbin/wmcs-spreadcheck',
                "/etc/wmcs-spreadcheck-${project}.yaml"
            ],
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
        }
    }

    # renaming cleanup
    $files = [
        '/usr/local/bin/spreadcheck.py',
        '/usr/local/etc/spreadcheck-tools.yaml',
    ]

    file { $files:
        ensure => 'absent',
    }
}
