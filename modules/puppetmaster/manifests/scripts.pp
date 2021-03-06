# Class: puppetmaster::scripts
#
# This class installs some puppetmaster server side scripts required for the
# manifests
#
# == Parameters
#
# [*keep_reports_minutes*]
#   Number of minutes to keep older reports for before deleting them.
#   The job to remove these is run only every 8 hours, however,
#   to prevent excess load on the prod puppetmasters.
class puppetmaster::scripts(
    Integer      $keep_reports_minutes = 960, # 16 hours
    Boolean      $has_puppetdb         = true,
    Stdlib::Host $ca_server            = $facts['fqdn'],
    Hash[String, Puppetmaster::Backends] $servers = {},
){

    $masters = $servers.keys().filter |$server| { $server != $facts['fqdn'] }
    $workers = $servers.values().map |$worker| {
        $worker.map |$name| { $name['worker'] }.filter |$name| { $name != $facts['fqdn'] }
    }.flatten()
    $puppet_merge_conf = @("CONF")
    # Generated by Puppet
    MASTERS="${masters.join(' ')}"
    WORKERS="${workers.join(' ')}"
    CA_SERVER="${ca_server}"
    | CONF

    # export and sanitize facts for puppet compiler
    ensure_packages(['python3-requests', 'python3-yaml'])

    file{'/etc/puppet-merge.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => $puppet_merge_conf,
    }

    file{'/usr/local/bin/puppet-merge':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/puppet-merge.sh',
    }
    file{'/usr/local/bin/puppet-merge.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/puppet-merge.py',
    }

    file {'/usr/local/bin/puppet-facts-export-puppetdb':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/puppet-facts-export-puppetdb.py',
    }

    # this performs the same task as puppet-facts-export but can
    #  run on a host without puppetdb.  This is useful because
    #  the cloud puppetmasters don't use puppetdb to preserve
    #  tenant separation
    file {'/usr/local/bin/puppet-facts-export-nodb':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/puppet-facts-export-nodb.sh',
    }

    # Link to the appropriate fact exporter, as appropriate
    #  depending on the presence of puppetdb
    $puppet_facts_export = $has_puppetdb ? {
        false   => '/usr/local/bin/puppet-facts-export-nodb',
        default => '/usr/local/bin/puppet-facts-export-puppetdb',
    }
    file { '/usr/local/bin/puppet-facts-export':
        ensure => link,
        target => $puppet_facts_export
    }

    # Clear out older reports
    systemd::timer::job { 'remove_old_puppet_reports':
        ensure      => 'present',
        user        => 'root',
        description => 'Clears out older puppet reports.',
        command     => "/usr/bin/find /var/lib/puppet/reports -type f -mmin +${keep_reports_minutes} -delete",
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '8h'},
    }

}
