# = Class: profile::prometheus::node_directorysize
#
# Periodically export directory sizes for configured directories via node-exporter textfile collector.
#
# directory_size_paths is a Hash of name to Hash of path and optionally filter keys.
# Example directory_size_paths:
# {
#   'misc_home': {
#     'path': '/exp/project/*/home',
#     'filter': '*/tools/*'
#   }
# }

class profile::prometheus::node_directory_size (
  $ensure = hiera('profile::prometheus::node_directory_size::ensure', 'present'),
  $directory_size_paths = hiera('profile::prometheus::node_directory_size::directory_size_paths', {}),
  $outfile = hiera('profile::prometheus::node_directory_size::outfile', '/var/lib/prometheus/node.d/node_directory_size_bytes'),
) {

  if ($ensure == 'absent') {
    file { "${outfile}.prom":
      ensure => 'absent'
    }
  }

  file { '/usr/local/bin/prometheus-directory-size':
    ensure => $ensure,
    mode   => '0555',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/profile/prometheus/node-directory-size.sh'
  }

  file { '/etc/default/prometheus-directory-size':
    ensure  => $ensure,
    mode    => '0555',
    owner   => 'root',
    group   => 'root',
    content => template('profile/prometheus/node-directory-size.erb')
  }

  # Collect every 10 minutes
  cron { 'prometheus_directorysize':
    ensure  => $ensure,
    user    => 'root',
    minute  => '*/10',
    command => '/usr/local/bin/prometheus-directory-size -c /etc/default/prometheus-directory-size',
  }
}
