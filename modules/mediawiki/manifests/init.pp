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
    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::mediawiki::scap
    include ::mediawiki::users
    include ::mediawiki::syslog
    include ::mediawiki::php

    if os_version('ubuntu >= trusty') {
        include ::mediawiki::hhvm
    }

    # Set the Salt grain 'php' to the name of the PHP runtime, to make
    # it easier to select a subset of MediaWiki servers. For example:
    #   $ salt -G php:hhvm cmd.run 'apt-show-versions hhvm'
    $php = $::lsbdistcodename ? { trusty => 'hhvm', default => 'php5' }
    salt::grain { 'php': value => $php }

    # /var/log/mediawiki contains log files for the MediaWiki jobrunner
    # and for various periodic jobs that are managed by cron.
    file { '/var/log/mediawiki':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0644',
    }

}
