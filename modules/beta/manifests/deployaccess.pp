class beta::deployaccess(
    $bastion_ip = '10.68.16.58', # ip of deployment-bastion
) {
    # Hack to replace /etc/security/access.conf (which is managed by the
    # ldap::client class) with a modified version that includes an access
    # grant for the mwdeploy user to authenticate from deployment-bastion.
    file { '/etc/security/access.conf~':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('beta/pam-access.conf.erb'),
    }
    File <| title == '/etc/security/access.conf' |> {
        content => undef,
        source  => '/etc/security/access.conf~',
        require => File['/etc/security/access.conf~'],
    }
}
