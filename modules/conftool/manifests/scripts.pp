# == Class conftool::scripts
#
# Install some useful scripts that can be used to pool/depool/drain a server
# from all the pools it is in.
#
# Example:
#
#class some::service {
#    user { 'foo': }
#
#    conftool::credentials { 'foo': }
#
#    include conftool::scripts
#}
class conftool::scripts {
    require ::conftool

    file { '/usr/local/bin/pooler-loop':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/conftool/pooler_loop.rb',
    }

    file { '/usr/local/bin/pool':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('conftool/pool.erb'),
    }

    file { '/usr/local/bin/depool':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('conftool/depool.erb'),
    }

    file { '/usr/local/bin/drain':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('conftool/drain.erb'),
    }

    file { '/usr/local/bin/decommission':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('conftool/decommission.erb'),
    }

}
