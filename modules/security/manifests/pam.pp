

define security::pam::config(
    $source = undef,
    $contents = undef,
)
{
    include security::pam::configs

    file { "/usr/share/pam-configs/$name":
        ensure   => present,
        source   => $source,
        contents => $contents,
        owner    => 'root',
        group    => 'root',
        mode     => '0444',
        notify   => Exec['pam-auth-update'],
    }
}

class security::pam::configs
{
    exec { 'pam-auth-update':
        command     => '/usr/sbin/pam-auth-update --package',
        refreshonly => true,
    }
}

