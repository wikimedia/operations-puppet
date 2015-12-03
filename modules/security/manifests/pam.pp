# == security::pam::config ==
#
# Allows adding a PAM configuration file to the system configuration.
# viz.: https://wiki.ubuntu.com/PAMConfigFrameworkSpec for syntax.
#
# The configuration files are //not// in a recursively managed puppet
# directory because system debian packages also add files there; to
# remove one you need to explicitly set it to ensure => absent
#
# Having a security::pam::config resource in the manifest implicitly
# pulls in the security::pam::configs class.
#
# === Parameters ===
#
# [*ensure*]
#  Is the usual metaparameter, defaults to present. Valid values are 'present'
#  and 'absent'.
#
# [*content*]
#   The content of the PAM configuration file.  Either this or [*source*]
#   must be specified.
#
# [*source*]
#   The source of the PAM configuration file.  Either this or [*content*]
#   must be specified.
#

define security::pam::config(
    $ensure  = present,
    $source  = undef,
    $content = undef,
)
{
    include security::pam::configs

    validate_ensure($ensure)

    file { "/usr/share/pam-configs/${name}":
        ensure  => $ensure,
        source  => $source,
        content => $content,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['pam-auth-update'],
    }
}

class security::pam::configs
{
    exec { 'pam-auth-update':
        command     => '/usr/sbin/pam-auth-update --package',
        refreshonly => true,
    }
}

