# SPDX-License-Identifier: Apache-2.0
class aptly::client (
    Stdlib::Fqdn          $servername,
    Array[String[1]]      $components   = ['main'],
    Enum['http', 'https'] $protocol     = 'http',
    Boolean               $auto_upgrade = true,
) {
    apt::repository { 'project-aptly':
        uri        => "${protocol}://${servername}/repo",
        dist       => "${::lsbdistcodename}-${::wmcs_project}",
        components => $components.join(' '),
        trust_repo => true,
        source     => false,
    }

    # Pin it so it has higher preference
    apt::pin { 'project-aptly':
        package  => '*',
        pin      => "origin ${servername}",
        priority => 1500,
    }

    apt::conf { 'unattended-upgrades-aptly':
        ensure   => $auto_upgrade.bool2str('present', 'absent'),
        priority => '52',
        # Key with trailing '::' to append to potentially existing entry
        key      => 'Unattended-Upgrade::Origins-Pattern::',
        value    => "site=${servername}",
    }
}
