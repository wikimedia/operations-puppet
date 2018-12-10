# Role to run services from docker images in beta
#
# filtertags: labs-project-deployment-prep
class role::beta::docker_services {
    include ::standard
    include ::profile::docker::engine
    include ::profile::docker::runner
    system::role { 'Service running via docker': }
}
