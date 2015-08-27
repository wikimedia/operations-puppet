class aptly::client(
    $servername,
) {
    apt::repository { 'project-aptly':
        uri        => "http://${servername}/repo",
        dist       => "${::lsbdistcodename}-${::labsproject}",
        components => 'main',
        source     => true,
    }
}
