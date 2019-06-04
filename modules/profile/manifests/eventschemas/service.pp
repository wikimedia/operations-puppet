# == Class profile::eventschemas::service
#
# Includes profile::eventschemas::repositories and sets up an HTTP site to serve
# static schema repository files over HTTP.
#
class profile::eventschemas::service(
    # Linter thinks that $::site is a parameter, but it isn't.
    # lint:ignore:wmf_styleguide
    $server_name  = hiera('profile::eventschemas::service::server_name', "schema.svc.${::site}.wmnet"),
    # lint:endignore
    $server_alias = hiera('profile::eventschemas::service::server_alias', undef),
    $port         = hiera('profile::eventschemas::service::port', 8190),
) {
    include ::profile::eventschemas::repositories
    class { '::eventschemas::service':
        server_name  => $server_name,
        server_alias => $server_alias,
        port         => $port,
    }

    ferm::service { 'eventschemas_service_http':
        proto => 'tcp',
        port  => $port,
    }
}