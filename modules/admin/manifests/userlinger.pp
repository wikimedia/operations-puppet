# A defined type for enabling lingering for a user
#
# === Parameters
#
# [*name*]
#  User name
#
# [*ensure*]
#  Present enables lingering, absent disables lingering.
#  Default: present

define admin::userlinger (
    Wmflib::Ensure $ensure = 'present',
) {

    file {"/var/lib/systemd/linger/${name}":
        ensure  => stdlib::ensure($ensure, 'file'),
        require => File['/var/lib/systemd/linger'],
    }
}
