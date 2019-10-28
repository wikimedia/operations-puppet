# conftool::scripts::initialize: simple script to
# set up a node with a default weight and pooled state.
#
# This is a class as it should be only initialized once per node.
class conftool::scripts::initialize(Hash[String, Integer] $services) {
    file { '/usr/local/sbin/initialize':
        ensure  => present,
        content => template('conftool/initialize.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555'
    }
}
