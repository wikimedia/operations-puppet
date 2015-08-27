class aptly::client(
    $servername,
) {
    apt::repository { 'project-aptly':
        uri        => "http://${servername}/repo",
        dist       => "${::labsproject}-$::lsbdistcodename",
        components => 'main',
        source     => true,
    }
}
