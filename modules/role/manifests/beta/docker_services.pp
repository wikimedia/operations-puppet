# Role to run services from docker images in beta
#
class role::beta::docker_services {
    include ::profile::base::production
    include ::profile::docker::engine
    include ::profile::docker::prune
    include ::profile::docker::runner
    system::role { 'Service running via docker': }
}
