# == Class: dnsdist
#
# Install and configure dnsdist.
#
# == Parameters:
#
#  [*resolvers*]
#    [hash] downstream recursive resolvers to their configuration. required.
#
#  [*cert_chain*]
#    [path] path to the certificate chain. used for dns-over-https/dns-over-tls. required.
#
#  [*cert_privkey*]
#    [path] path to the certificate private key. used for dns-over-https/dns-over-tls. required.
#
#  [*maxqps*]
#    [int] number of queries allowed per second from an IP. default: 10.

class dnsdist (
    Hash[String, Dnsdist::Resolver] $resolvers,
    Stdlib::Unixpath                $cert_chain,
    Stdlib::Unixpath                $cert_privkey,
    Integer[1]                      $maxqps       = 10,
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
