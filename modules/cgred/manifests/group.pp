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
#
#
# The docs say 'First rule which matches the criteria will be executed.'
#
# - This applies even across different subsystems
# - Use the '%' keyword char to apply multiple lines upon first match.
# - Keep in mind cgroups are inherited by child processes
#
# Example that results in membership only in cpu shell cgroup:
#
#  *:/bin/bash           cpu         /shell
#  *:/bin/bash           memory      /shell
#
# Example that results in membershp in cpu and memory shell cgroup:
#
#  *:/bin/bash           cpu         /shell
#  %                     memory      /shell
#
# See: man cgrules.conf

define cgred::group (
    $ensure = 'present',
    $config = {},
    $rules  = [],
    $order  = '50',
)
    {

    include ::cgred
    file {"/etc/cgconfig.d/${name}.conf":
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('cgred/cgconfig.conf.erb'),
        require => File['/etc/cgconfig.d/'],
        notify  => Base::Service_unit['cgrulesengd'],
    }

    file {"/etc/cgrules.d/${order}-${name}.conf":
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('cgred/cgrules.conf.erb'),
        require => File['/etc/cgrules.d/'],
        notify  => Base::Service_unit['cgrulesengd'],
    }
}
