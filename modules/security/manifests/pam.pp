# == security::pam ==
#
# This class is pulled in implicitly by the security::pam::config
# resources to allow PAM reconfiguration when we install local
# configs.

class security::pam {
    exec { 'pam-auth-update':
        command     => '/usr/sbin/pam-auth-update --package',
        refreshonly => true,
    }
}

