# == Class: openstack::monitor::spreadcheck
# NRPE check to see if critical instances for a project
# are spread out enough among the labvirt* hosts
class openstack::monitor::spreadcheck {
    # Script that checks how 'spread out' critical instances for a project
    # are. See T101635
    file { '/usr/local/sbin/wmcs-spreadcheck':
        ensure => absent,
    }

    ['tools', 'deployment-prep', 'cloudinfra'].each |String $project| {
        file { "/etc/wmcs-spreadcheck-${project}.yaml":
            ensure => absent,
        }
    }
}
