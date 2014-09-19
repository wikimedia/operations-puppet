# == Class: mediawiki::syslog
#
# Hosts running MediaWiki configure Apache and HHVM to log to syslog.
# This Puppet class configures rsyslog to handle log messages from
# Apache and HHVM by writing them to disk and forwarding them to the
# MediaWiki log aggregator via UDP. It also sets up log rotation for the
# local log files.
#
class mediawiki::syslog {

    # We assign a priority of 40 to MediaWiki's rsyslog config file
    # so we can intercept log messages before they fall through to
    # the firehose in 50-default.conf.

    rsyslog::conf { 'mediawiki':
        source   => 'puppet:///modules/mediawiki/rsyslog.conf',
        priority => 40,
    }


    # Set up log rotation for /var/log/apache2.log. In addition to
    # cron-triggered rotation, rsyslog will invoke logrotate whenever
    # apache2.log exceeds 100MB.

    file { '/etc/logrotate.d/mediawiki_apache':
        source => 'puppet:///modules/mediawiki/logrotate.d_mediawiki_apache',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Rsyslog::Conf['mediawiki'],
    }
}
