# = Class: striker::build
#
# Packages and config needed for a host that can build wheels for Striker
#
class striker::build {
    requires_os('debian stretch')
    require_package(
        'build-essential',
        'git-review',
        'libffi-dev',
        'libldap2-dev',
        'libmariadbclient-dev',
        'libsasl2-dev',
        'libssl-dev',
        'python3',
        'python3-dev',
        'python3-venv',
        'python3-virtualenv',
        'python3-wheel',
        'realpath',
    )
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
