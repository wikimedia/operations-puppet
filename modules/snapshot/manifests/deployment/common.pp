class snapshot::deployment::common (
    $owner = undef,
    $group = undef,
) {
    $repodir = '/srv/deployment/dumps'
    file { $repodir:
        ensure => 'directory',
        path   => $repodir,
        mode   => '0755',
        owner  => $owner,
        group  => $group,
    }
    $scriptsdir = '/srv/deployment/dumps/dumps'
}
