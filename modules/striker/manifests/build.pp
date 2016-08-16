# = Class: striker::build
#
# Packages and config needed for a host that can build wheels for Striker
#
class striker::build {
    requires_os('Debian >= jessie')
    require_package(
        'build-essential',
        'libffi-dev',
        'libldap2-dev',
        'libmysqlclient-dev',
        'libsasl2-dev',
        'libssl-dev',
        'python3',
        'python3-dev',
        'python3-wheel',
        'virtualenv',
    )
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
