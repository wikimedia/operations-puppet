# SPDX-License-Identifier: Apache-2.0
class aptly::client(
    $servername="${::labsproject}-packages.${::labsproject}.${::site}.wmflabs",
    $source=false,
    $components='main',
    $protocol='http',
) {
    apt::repository { 'project-aptly':
        uri        => "${protocol}://${servername}/repo",
        dist       => "${::lsbdistcodename}-${::labsproject}",
        components => $components,
        source     => $source,
        trust_repo => true,
    }

    # Pin it so it has higher preference
    apt::pin { 'project-aptly':
        package  => '*',
        pin      => "origin ${servername}",
        priority => 1500,
    }
}
