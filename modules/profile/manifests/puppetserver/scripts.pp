# SPDX-License-Identifier: Apache-2.0
# @summary
#   This class installs some puppetserver server side scripts required for the
#   manifests
#   https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Manually_update_cloud
# @param keep_reports_minutes
#   Number of minutes to keep older reports for before deleting them.
#   The job to remove these is run only every 8 hours, however,
#   to prevent excess load on the prod puppetservers.
# @param has_puppetdb inidcate if the system uses puppetdb
# @param http_proxy the http proxy to use
# @param realm_override
#   this is use to override the realm used for the facts upload. its only really
#   used if you have two puppet servers in the same projects servicing different
#   clients e.g. cloudinfra
class profile::puppetserver::scripts (
    Integer                   $keep_reports_minutes = lookup('profile::puppetserver::scripts::keep_reports_minutes'),
    Boolean                   $has_puppetdb         = lookup('profile::puppetserver::scripts::has_puppetdb'),
    Optional[Stdlib::HTTPUrl] $http_proxy           = lookup('profile::puppetserver::scripts::http_proxy'),
    Optional[String[1]]       $realm_override       = lookup('profile::puppetserver::scripts::realm_override'),
){
    include profile::puppetserver
    # only upload facts from the ca server
    $upload_facts = $profile::puppetserver::enable_ca
    # export and sanitize facts for puppet compiler
    ensure_packages(['python3-cryptography', 'python3-requests', 'python3-yaml'])

    $puppet_facts_export_source = $has_puppetdb ? {
        false   => 'puppet:///modules/profile/puppetserver/scripts/puppet7-facts-export-nodb.py',
        default => 'puppet:///modules/profile/puppetserver/scripts/puppet-facts-export-puppetdb.py',
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
        source => 'puppet:///modules/profile/puppetserver/scripts/puppet-facts-upload.py',
    }

    $proxy_arg = $http_proxy.then |$x| { "--proxy ${http_proxy}" }
    $realm_arg = $realm_override.then |$x| { "--realm ${realm_override}" }

    systemd::timer::job { 'upload_puppet_facts':
        ensure      => $upload_facts.bool2str('present', 'absent'),
        user        => 'root',
        description => 'Upload facts export to puppet compiler',
        command     => "/usr/local/sbin/puppet-facts-upload ${proxy_arg} ${realm_arg}",
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
    }

    # Clear out older reports
    systemd::timer::job { 'remove_old_puppet_reports':
        ensure      => 'present',
        user        => 'root',
        description => 'Clears out older puppet reports.',
        command     => "/usr/bin/find /var/lib/puppetserver/reports -type f -mmin +${keep_reports_minutes} -delete",
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '8h'},
        path_exists => '/var/lib/puppetserver/reports',
    }
}
