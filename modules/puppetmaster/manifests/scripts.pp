# Class: puppetmaster::scripts
#
# This class installs some puppetmaster server side scripts required for the
# manifests
#
# == Parameters
#
# [*keep_reports_minutes*]
#   Number of minutes to keep older reports for before deleting them.
#   The cron to remove these is run only every 8 hours, however,
#   to prevent excess load on the prod puppetmasters.
class puppetmaster::scripts(
    $keep_reports_minutes = 960, # 16 hours
) {
    $prodservers = hiera('puppetmaster::servers', {})

    # This is a temporary hack; it can be removed once T171188 is resolved
    #  and wmcs puppetmasters are more decoupled from prod
    $wmcsservers = hiera('profile::openstack::eqiad1::puppetmaster::servers', {})
    $servers = $prodservers + $wmcsservers

    file{'/usr/local/bin/puppet-merge':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('puppetmaster/puppet-merge.erb'),
    }

    # export and sanitize facts for puppet compiler
    require_package('python3-requests', 'python3-yaml')
    file {'/usr/local/bin/puppet-facts-export':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/puppet-facts-export.py',
    }

    # Clear out older reports
    cron { 'removeoldreports':
        ensure  => present,
        command => "find /var/lib/puppet/reports -type f -mmin +${keep_reports_minutes} -delete >/dev/null 2>&1",
        user    => puppet,
        hour    => [0, 8, 16], # Run every 8 hours, to prevent excess load
        minute  => 27, # Run at a time when hopefully no other cron jobs are
    }

    # Helper script to clean stored data about a server we're reimaging.
    if $::realm == 'production' {
        file { '/usr/local/sbin/install-console':
            ensure => 'present',
            owner  => 'root',
            group  => 'root',
            mode   => '0544',
            source => 'puppet:///modules/puppetmaster/install-console',
        }
    }
}
