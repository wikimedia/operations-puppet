class aptly::client(
    $servername,
    $source=false
) {
    if os_version('ubuntu <= precise') {
        # Remove multiarch support in precise aptly clients.
        # Can be removed when T111760 is fixed
        file { '/etc/dpkg/dpkg.cfg.d/multiarch':
            ensure => absent,
            notify => Exec['apt-get update'],
        }
    }

    apt::repository { 'project-aptly':
        uri        => "http://${servername}/repo",
        dist       => "${::lsbdistcodename}-${::labsproject}",
        components => 'main',
        source     => $source,
    }
}
