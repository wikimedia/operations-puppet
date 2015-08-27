class aptly::client(
    $servername,
) {
    apt::repository { 'project-aptly':
        uri        => "http://${servername}/repo",
        dist       => $::lsbdistcodename,
        components => $::labsproject,
        source     => true,
    }
}
