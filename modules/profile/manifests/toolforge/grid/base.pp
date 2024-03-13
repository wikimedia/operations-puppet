# This establishes the basics for every SGE node

class profile::toolforge::grid::base (
    Stdlib::Unixpath $project_path = lookup('profile::toolforge::grid::base::project_path', {default_value => '/data/project'}),
) {
    exec { 'ensure-grid-is-on-NFS':
        command => '/bin/false',
        unless  => "/usr/bin/timeout -k 5s 60s /usr/bin/test -e ${project_path}/herald",
    }

    file { '/shared':
        ensure  => link,
        target  => "${project_path}/.shared",
        require => Exec['ensure-grid-is-on-NFS'],
    }

    # Link to currently active proxy
    file { '/etc/active-proxy':
        ensure => absent,
    }

    class { 'profile::prometheus::node_local_crontabs': }
}
