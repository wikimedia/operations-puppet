# == security::access ==
#
# This class is included implicitly by security::access::config resources
# to create the access.conf.d directory and add access.conf checking to
# the system PAM configuration.
#

class security::access {

    file { '/etc/security/access.conf.d':
        ensure  => directory,
        recurse => true,
        purge   => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        notify  => Exec['merge-access-conf'],
    }

    exec { 'merge-access-conf':
        refreshonly => true,
        cwd         => '/etc/security',
        command     => '/bin/cat access.conf.d/* >access.conf~ && mv access.conf~ access.conf',
    }

    security::pam::config { 'local-pam-access':
        source => 'puppet:///modules/security/local-pam-access',
    }

}

