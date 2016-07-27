# = Class: striker::uwsgi
#
# Striker is a Django application for managing data related to Tool Labs
# tools.
#
# == Parameters:
# [*deploy_dir*]
#   Directory that Striker will be deployed to via scap3.
#
# [*venv_dir*]
#   Directory to create/manage Python virtualenv in.
#
# [*port*]
#   Port that uWSGI demon should listen on
#
class striker::uwsgi(
    $deploy_dir = '/srv/deployment/striker/deploy',
    $venv_dir   = '/srv/deployment/striker/venv',
    $port,
){
    # Packages needed by python wheels
    require_package(
        'libffi',
        'libldap2',
        'libmysqlclient',
        'libsasl2',
        'libssl',
        'python3',
        'virtualenv',
    )

    # TODO: generate Striker ini file

    service::uwsgi { 'striker':
        port            => $port,
        config          => {
            'chdir'     => "${::striker::deploy_dir}/striker",
            'wsgi-file' => 'striker/wsgi.py',
            'plugins'   => 'python3',
            'venv'      => "${::striker::deploy_dir}/venv",
        },
        healthcheck_url => '/',
        repo            => 'labs/striker/deploy',
        sudo_rules      => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker *',
        ],
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
