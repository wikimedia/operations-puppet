# == Class: mediawiki
#
# MediaWiki is the collaborative editing software that runs Wikipedia.
# It powers some of the most highly-trafficked sites on the web, serving
# content in over a hundred languages to more than half a billion people
# each month.
#
# This module configures Wikimedia's execution environment for
# MediaWiki, which comprises software packages and service
# configuration.
#
class mediawiki {
    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::mediawiki::scap
    include ::mediawiki::users
    include ::mediawiki::syslog
    include ::mediawiki::php

    include ::ssh::server

    if ubuntu_version('>= trusty') {
        include ::mediawiki::hhvm
    }


    # Increase the scheduling priority of sshd so we can still
    # log in remotely in cases of overload.

    file { '/etc/init/ssh.override':
        content => "nice -10\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['ssh'],
    }


    # /var/log/mediawiki contains log files for the MediaWiki jobrunner
    # and for various periodic jobs that are managed by cron.

    file { '/var/log/mediawiki':
        ensure => directory,
        owner  => 'apache',
        group  => 'wikidev',
        mode   => '0644',
    }
}
