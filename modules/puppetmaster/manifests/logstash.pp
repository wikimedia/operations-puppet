# = Class: puppetmaster::logstash
#
# Deploy and configure a puppet reporter to send reports to logstash.
#
# This results in the full diff of the Puppet run being stored in Logstash. As
# such, care should be taken in ensuring that the target logstash cluster is
# properly secured for types of sensitive data that this may reveal.
#
# == Parameters
# - logstash_host: Host to send log events to
# - logstash_port: Port to send log events to
# - timeout: Connection timeout for sending an event in seconds. Default is 5.
class puppetmaster::logstash(
    $logstash_host,
    $logstash_port,
    $timeout = 5,
) {
    include base::puppet

    file { '/etc/puppet/logstash.yaml':
        ensure  => present,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '0444',
        content => template('puppetmaster/logstash.yaml.erb'),
    }

    file { '/etc/puppet/puppet.conf.d/30-logstash.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppetmaster/30-logstash.conf.erb'),
        notify  => Class['base::puppet'],
    }
}
