# == Class: nutcracker
#
# nutcracker (AKA twemproxy) is a fast and lightweight proxy
# for memcached and redis. It was primarily built to reduce the
# connection count on the backend caching servers.
#
# === Parameters
#
# [*mbuf_size*]
#   When set, will determine the size of nutcracker's mbufs.
#   The default is 16384. See <https://github.com/twitter/twemproxy
#   /blob/b2cd3ad/notes/recommendation.md> for a discussion of this
#   option.
#
# [*verbosity*]
#   Set logging level (default: 4, min: 0, max: 11).
#
# [*pools*]
#   A hash defining a nutcracker server pool.
#   See <https://github.com/twitter/twemproxy#configuration>.
#
# === Examples
#
#  class { '::nutcracker':
#    pools => {
#      'parser' => {
#        listen       => '127.0.0.1:11211',
#        distribution => 'ketama',
#        hash         => 'md5',
#        timeout      => 250,
#        servers      => ['10.64.0.180:11211:1', '10.64.0.181:11211:1'],
#      },
#    },
#  }
#
class nutcracker(
    $pools,
    $ensure    = present,
    $mbuf_size = undef,
    $verbosity = 4,
) {
    validate_hash($pools)
    validate_re($ensure, '^(present|absent)$')
    validate_re($verbosity, '^(\d|10|11)$')

    package { 'nutcracker':
        ensure => $ensure,
    }

    file { '/etc/nutcracker/nutcracker.yml':
        ensure  => $ensure,
        content => template('nutcracker/nutcracker.yml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['nutcracker'],
    }

    if (
        $ensure == 'present' and
        versioncmp($::puppetversion, '3.5') >= 0 and
        versioncmp($::serverversion, '3.5') >= 0
        ) {
        File['/etc/nutcracker/nutcracker.yml'] {
          validate_cmd => '/usr/bin/test \! -f /etc/nutcracker/nutcracker.yml || /usr/sbin/nutcracker --test-conf %',
        }
    }

    file { '/etc/default/nutcracker':
        ensure  => $ensure,
        content => template('nutcracker/default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['nutcracker'],
    }

    file { '/etc/init/nutcracker.override':
        ensure  => $ensure,
        content => "limit nofile 64000 64000\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['nutcracker'],
    }

    service { 'nutcracker':
        ensure => ensure_service($ensure),
    }
}
