# == Class: dnsdist
#
# Install and configure dnsdist.
#
# == Parameters:
#
#  [*resolvers*]
#    [hash] downstream recursive resolvers to their configuration. required.

class dnsdist (
    Hash[String, Dnsdist::Resolver] $resolvers,
) {

    apt::package_from_component { 'dnsdist':
        component => 'component/dnsdist',
    }

    file { '/etc/dnsdist/dnsdist.conf':
        ensure  => 'present',
        require => Package['dnsdist'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('dnsdist/dnsdist.conf.erb'),
        notify  => Service['dnsdist'],
    }

    service { 'dnsdist':
        ensure     => 'running',
        require    => Package['dnsdist'],
        hasrestart => true,
    }

}
