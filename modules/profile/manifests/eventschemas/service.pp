# == Class profile::eventschemas::service
#
# Includes profile::eventschemas::repositories and sets up an HTTP site to serve
# static schema repository files over HTTP.
#
class profile::eventschemas::service(
    # Linter thinks that $::site is a parameter, but it isn't.
    # lint:ignore:wmf_styleguide
    Stdlib::Fqdn $server_name      = lookup('profile::eventschemas::service::server_name', {default_value => "schema.svc.${::site}.wmnet"}),
    # lint:endignore
    Optional[Array] $server_alias  = lookup('profile::eventschemas::service::server_alias', {default_value => undef}),
    Stdlib::Port $port             = lookup('profile::eventschemas::service::port', {default_value => 8190}),
    Optional[String] $allow_origin = lookup('profile::eventschemas::service::allow_origin', {default_value => undef}),
) {
    include ::profile::eventschemas::repositories
    class { '::eventschemas::service':
        server_name  => $server_name,
        server_alias => $server_alias,
        port         => $port,
        allow_origin => $allow_origin,
    }

    ferm::service { 'eventschemas_service_http':
        proto => 'tcp',
        port  => $port,
    }
}
