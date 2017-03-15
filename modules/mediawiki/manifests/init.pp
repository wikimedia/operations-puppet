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

    # This profile is used to contain the convert command of imagemagick using
    # firejail Profiles specific to the image/video scalers are handled via
    # mediawiki::firejail, but imagemagick is also used on the general purpose
    # appscalers for scaling musical typesheets in the Score extension
    file { '/etc/firejail/mediawiki-imagemagick.profile':
        source  => 'puppet:///modules/mediawiki/mediawiki-imagemagick.profile',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['firejail'],
    }

    file { '/usr/local/bin/mediawiki-firejail-convert':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-convert',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/firejail/mediawiki-converters.profile':
        source => 'puppet:///modules/mediawiki/mediawiki-converters.profile',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/local/bin/mediawiki-firejail-ghostscript':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-ghostscript',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
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
