# Establish a cgroup with parameters and rules to enforce
#
# cgroup-lite is a dependency pulled in
# by cgroup-bin in init.  cgroup-lite
# takes care of mounting the initial cgroup
# subsystems upon boot.
#
# [*config]
#  Hash of values for cgroup settings
#
#    cgred::group {'mygrouping':
#        config => {
#            cpu => {
#                'cpu.shares' => '1',
#            },
#        }
#        rules  => [
#            '*:foo.sh subsystem /cgroup',
#        ]
#    }

define cgred::group (
    $ensure = 'present',
    $config = {},
    $rules  = [],
)
    {

    include cgred
    file {"/etc/cgconfig.d/${name}.conf":
        ensure  => $ensure,
        mode    => '0400',
        owner   => 'root',
        group   => 'root',
        content => template('cgred/cgconfig.conf.erb'),
        require => File['/etc/cgconfig.d/'],
        notify  => Base::Service_unit['cgrulesengd'],
    }

    file {"/etc/cgrules.d/${name}.conf":
        ensure  => $ensure,
        mode    => '0400',
        owner   => 'root',
        group   => 'root',
        content => template('cgred/cgrules.conf.erb'),
        require => File['/etc/cgrules.d'],
        notify  => Base::Service_unit['cgrulesengd'],
    }
}
