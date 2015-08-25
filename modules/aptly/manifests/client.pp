class aptly::client(
    $servername,
) {
    apt::repository { 'project-aptly':
        url        => "http://${servername}/repo",
        dist       => $::lsbdistcodename,
        components => $::labsproject,,
        source     => true,
    }
}
