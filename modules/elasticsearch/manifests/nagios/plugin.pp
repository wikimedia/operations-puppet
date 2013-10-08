# == Class elasticsearch::icinga
# Includes the check_elasticsearch shell script.
# include this class on your Nagios/Icinga node.
#
class elasticsearch::nagios::plugin {
    @file { '/usr/lib/nagios/plugins/check_elasticsearch':
      source  => 'puppet:///modules/elasticsearch/nagios/check_elasticsearch',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => Package['icinga'],
      tag => 'nagiosplugin'
    }
}
