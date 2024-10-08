# SPDX-License-Identifier: Apache-2.0
# @summary Deploy a FastAPI application
#
# This define installs a FastAPI application and sets up a systemd service to run it.
#
# It works using convention over configuration, so it assumes the application
# is organized as expected by the Python deploy module, in a "deploy" repository.
# It also expects your code to have a main.py file that defines an app variable
# that is a FastAPI instance.
#
# @param port Stdlib::Port::Unprivileged The port to listen on
# @param bind_addr Stdlib::IP::Address The address to bind the service to
# @param workers Integer The number of worker processes to run
# @param disable_reload boolean Whether to disable the automatic reload feature
#       of Uvicorn. This might be useful in production if releases should be coordinated.
# @param log_level String The log level to use for the Uvicorn server
define fastapi::application (
    Stdlib::Port::Unprivileged $port,
    Stdlib::IP::Address $bind_addr = '0.0.0.0',
    Integer $workers = 2,
    Boolean $disable_reload = false,
    String $log_level = 'info',
) {
    $app_basedir = "/srv/deployment/${title}"
    # Install the application
    python_deploy::venv { $title: }

    # Install the systemd service
    systemd::service { $title:
        ensure  => present,
        content => template('fastapi/systemd.service.erb'),
        require => Python_deploy::Venv[$title],
    }
}
