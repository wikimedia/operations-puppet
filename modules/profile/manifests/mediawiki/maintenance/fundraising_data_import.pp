# SPDX-License-Identifier: Apache-2.0
# Systemd timer that watches /var/lib/fundraising-data-uploader for new
# encrypted files (*.ready) and imports them into MediaWiki via mwscript-k8s.
# Puppet-level gate: only enabled on the host matching $deployment_server from
# hiera, which follows the deployment server switchover process (not
# WMFMasterDatacenter/etcd). See https://wikitech.wikimedia.org/wiki/Switch_Datacenter/DeploymentServer
class profile::mediawiki::maintenance::fundraising_data_import (
    String[1]        $age_identity     = lookup('profile::mediawiki::maintenance::fundraising_data_import::age_identity'),
    Stdlib::Host     $deployment_server = lookup('deployment_server'),
    String[1]        $mw_script        = lookup(
        'profile::mediawiki::maintenance::fundraising_data_import::mw_script',
        { default_value => 'extensions/WikimediaCustomizations/maintenance/DonorIdentification/syncDonorStatus.php' }
    ),
    String[1]        $wiki             = lookup(
        'profile::mediawiki::maintenance::fundraising_data_import::wiki',
        { default_value => 'metawiki' }
    ),
    Optional[String] $team             = lookup(
        'profile::mediawiki::maintenance::fundraising_data_import::team',
        { default_value => undef }
    ),
) {
    # Not applicable in the Cloud VPS (labs) environment.
    if $facts['realm'] == 'labs' {
        return()
    }

    # Only enable on the primary deployment server as defined by hiera.
    # This follows the deployment server switchover process, which happens
    # after the MediaWiki DC switchover (~1 day), so data files arrive at
    # the correct host. See https://wikitech.wikimedia.org/wiki/Switch_Datacenter/DeploymentServer
    $ensure = $facts['networking']['fqdn'] == $deployment_server ? {
        true  => 'present',
        false => 'absent',
    }

    $script_path        = '/usr/local/bin/fundraising-data-import'
    $identity_file_path = '/etc/fundraising-data-import.age-identity'

    ensure_packages(['age'])

    file { $script_path:
        ensure => stdlib::ensure($ensure, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/mediawiki/maintenance/fundraising_data_import.py',
    }

    # The age symmetric identity file holds the decryption key.
    # mode 0400 and show_diff => false ensure it is never world-readable
    # or exposed in Puppet reports/diffs.
    file { $identity_file_path:
        ensure    => stdlib::ensure($ensure, 'file'),
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        show_diff => false,
        content   => $age_identity,
    }

    systemd::timer::job { 'fundraising-data-import':
        ensure             => $ensure,
        description        => 'Import encrypted fundraising data files into MediaWiki via mwscript-k8s',
        command            => "${script_path} --script ${mw_script} --wiki ${wiki} --identity-file ${identity_file_path}",
        user               => 'root',
        interval           => {
            start    => 'OnCalendar',
            interval => '*-*-* 03:00:00',
        },
        monitoring_enabled => true,
        team               => $team,
        require            => [Package['age'], File[$script_path, $identity_file_path]],
    }
}

