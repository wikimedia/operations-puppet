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
    Hash             $pools,
    Wmflib::Ensure   $ensure    = present,
    Optional[String] $mbuf_size = undef,
    Integer[0,11]    $verbosity = 4,
) {

    ensure_packages(['nutcracker'])

    file {
        default:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            notify  => Service['nutcracker'],
            require => Package['nutcracker'];
        '/etc/nutcracker/nutcracker.yml':
            content      => template('nutcracker/nutcracker.yml.erb'),
            validate_cmd => '/usr/sbin/nutcracker --test-conf --conf-file %';
        '/etc/default/nutcracker':
            content => template('nutcracker/default.erb');
        '/etc/init/nutcracker.override':
            content => "limit nofile 64000 64000\n";
    }
    service { 'nutcracker':
        ensure  => ensure_service($ensure),
        require => Package['nutcracker'],
    }
}
