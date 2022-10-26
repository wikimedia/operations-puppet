# @summary
#   This class installs some puppetmaster server side scripts required for the
#   manifests
# @param keep_reports_minutes
#   Number of minutes to keep older reports for before deleting them.
#   The job to remove these is run only every 8 hours, however,
#   to prevent excess load on the prod puppetmasters.
# @param has_puppetdb inidcate if the system uses puppetdb
# @param upload_facts use the upload facts feature
#   https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Manually_update_cloud
# @param http_proxy the http proxy to use
class puppetmaster::scripts(
    Integer                              $keep_reports_minutes = 960, # 16 hours
    Boolean                              $has_puppetdb         = true,
    Boolean                              $upload_facts         = true,
    Optional[Stdlib::HTTPUrl]            $http_proxy           = undef,
){
    # export and sanitize facts for puppet compiler
    ensure_packages(['python3-requests', 'python3-yaml'])

    $puppet_facts_export_source = $has_puppetdb ? {
        false   => 'puppet:///modules/puppetmaster/puppet-facts-export-nodb.sh',
        default => 'puppet:///modules/puppetmaster/puppet-facts-export-puppetdb.py',
    }
    file { '/usr/local/bin/puppet-facts-export':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => $puppet_facts_export_source,
    }

    file { '/usr/local/sbin/puppet-facts-upload':
        ensure => stdlib::ensure($upload_facts, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0554',
        source => 'puppet:///modules/puppetmaster/puppet-facts-upload.py',
    }

    $timer_command = $http_proxy ? {
        undef   => '/usr/local/sbin/puppet-facts-upload',
        default => "/usr/local/sbin/puppet-facts-upload --proxy ${http_proxy}"
    }
    systemd::timer::job { 'upload_puppet_facts':
        ensure      => $upload_facts.bool2str('present', 'absent'),
        user        => 'root',
        description => 'Upload facts export to puppet compiler',
        command     => $timer_command,
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
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
