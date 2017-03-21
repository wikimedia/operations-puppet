# == Class: librenms::syslog
#
# Sets up a separate rsyslog instance that receives messages in syslog (UDP
# 514) and forwards them to librenms' syslog script.
#
# Using a separate instance seems more complicated at first but provides
# certain important benefits:
# * The separate instance runs as the librenms user and hence is able to read
#   the configuration file without giving access to the whole syslog group
# * There's no mixing of system syslog with the remote syslog and no messy
#   filtering to avoid logging the local system's logs to LibreNMS
# * The received loglines are only stored in LibreNMS and are not forwarded to
#  the rest of the syslog config (local log files, remote syslog servers etc.)
#
# == Parameters
#
# None.
class librenms::syslog {
    file { '/etc/librenms-rsyslog.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/librenms/rsyslog.conf',
        require => [
            File['/usr/local/sbin/librenms-syslog'],
            User['librenms'],
        ],
    }

    base::service_unit { 'librenms-syslog':
        ensure    => present,
        upstart   => true,
        systemd   => true,
        subscribe => File['/etc/librenms-rsyslog.conf'],
    }
}
