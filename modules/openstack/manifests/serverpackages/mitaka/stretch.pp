class openstack::serverpackages::mitaka::stretch(
) {

    # hack, use the jessie-backports repository in stretch. This should work,
    # since jessie-backports packages are rebuilt from stretch anyway
    apt::repository { 'jessie-backports-for-mitaka-on-stretch':
        uri        => 'http://mirrors.wikimedia.org/debian/',
        dist       => 'jessie-backports',
        components => 'main',
    }
}
