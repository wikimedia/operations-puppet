class aptly::client(
    $servername,
    $source=false,
    $components='main',
) {
    apt::repository { 'project-aptly':
        uri        => "http://${servername}/repo",
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
