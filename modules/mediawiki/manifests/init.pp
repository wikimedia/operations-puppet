# == Class: mediawiki
#
# MediaWiki is the collaborative editing software that runs Wikipedia.
# It powers some of the most highly-trafficked sites on the web, serving
# content in over a hundred languages to more than half a billion people
# each month.
#
# This module configures Wikimedia's MediaWiki execution environment,
# which comprises software packages and service configuration.
#
# === Parameters:
# [*log_aggregator*]
#   Udp2log aggregation server to send logs to. Default 'udplog:8420'.
#
# [*forward_syslog*]
#   Host and port to forward syslog events to. Default undef (no forwarding).
#
class mediawiki (
    $log_aggregator = 'udplog:8420',
    $forward_syslog = undef,
    ) {

    # Simplicity over support: precise is going out of support in April 2017 anyways
    requires_os('ubuntu >= trusty || Debian >= jessie')

    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::mediawiki::scap
    include ::mediawiki::users
    include ::mediawiki::syslog
    include ::mediawiki::php
    include ::mediawiki::mwrepl

    include ::mediawiki::hhvm

    file { '/usr/local/bin/mediawiki-firejail-convert':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-convert',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # We've set the 'php' grain in the past, but we don't really need it anymore
    salt::grain { 'php':
        ensure => absent,
        value  => 'hhvm',
    }

    # /var/log/mediawiki contains log files for the MediaWiki jobrunner
    # and for various periodic jobs that are managed by cron.
    file { '/var/log/mediawiki':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0644',
    }
}
