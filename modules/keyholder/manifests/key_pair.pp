# == Define: keyholder::private_key
#
# Provisions a private key file in /etc/keyholder.d.
#
# === Parameters
#
# [*ensure*]
#   If 'present', config will be enabled; if 'absent', disabled.
#   The default is 'present'.
#
# [*content*]
#   If defined, will be used as the content of the key file.
#   Undefined by default. Mutually exclusive with 'source'.
#
# [*source*]
#   Path to key file. Undefined by default.
#   Mutually exclusive with 'content'.
#
# === Examples
#
#  keyholder::private_key { 'mwdeploy_rsa':
#    ensure => present,
#    content => secret('ssh/tin/mwdeploy_rsa'),
#  }
#
define keyholder::key_pair(
    $title,
    $ensure  = present,
) {
    validate_ensure($ensure)

    $title_safe  = regsubst($title, '\W', '_', 'G')

    file { "/etc/keyholder.d/${title_safe}":
        ensure  => $ensure,
        content => keyholder_key($title_safe, true),
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }
}
