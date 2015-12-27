# == Class elasticsearch::nagios::plugin
# Includes the nagios checks for elasticsearch.
# include this class on your Nagios/Icinga node.
#
class elasticsearch::nagios::plugin {
    @file { '/usr/lib/nagios/plugins/check_elasticsearch':
      source  => 'puppet:///modules/elasticsearch/nagios/check_elasticsearch',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      tag     => 'nagiosplugin'
    }

    # new version, can do more fine-grained checks
    @file { '/usr/lib/nagios/plugins/check_elasticsearch.py':
      source  => 'puppet:///modules/elasticsearch/nagios/check_elasticsearch.py',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      tag     => 'nagiosplugin'
    }

    package { 'python-requests':
      ensure => 'installed',
      before => File['/usr/lib/nagios/plugins/check_elasticsearch.py'],
    }
}
