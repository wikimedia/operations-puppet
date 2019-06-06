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
    file { '/usr/local/bin/pooler-loop':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/conftool/pooler_loop.rb',
    }

    file { [
        '/usr/local/bin/pool',
        '/usr/local/bin/depool',
        '/usr/local/bin/drain',
        '/usr/local/bin/decommission'
    ]:
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/conftool/conftool-simple-command.sh',
    }

    file { '/usr/local/bin/safe-service-restart':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/conftool/safe-service-restart.py'
    }
}
