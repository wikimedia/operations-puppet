# = Class: nagios_common::check_dns_query
# This defines just the File resource for check_dns_query and the required perl
# modules. It's used by nagios_common::commands as well as profiles which need
# this for other healthcheck purposes.
class nagios_common::check_dns_query($ensure = present) {
    ensure_packages('libmonitoring-plugin-perl')
    ensure_packages('libnet-dns-perl')
    file { '/usr/lib/nagios/plugins/check_dns_query':
        ensure => $ensure,
        source => 'puppet:///modules/nagios_common/check_commands/check_dns_query',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
