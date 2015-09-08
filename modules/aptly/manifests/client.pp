class aptly::client(
    $servername,
    $source=false
) {
    apt::repository { 'project-aptly':
        uri        => "http://${servername}/repo",
        dist       => "${::lsbdistcodename}-${::labsproject}",
        components => 'main',
        source     => $source,
    }
}
