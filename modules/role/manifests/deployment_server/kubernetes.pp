# Deployment Server - including kubernetes stuff.
class role::deployment_server::kubernetes {

    include role::deployment_server
    # Kubernetes deployments
    include profile::kubernetes::deployment_server
    include profile::kubernetes::client
    include profile::kubernetes::deployment_server::helmfile
    include profile::kubernetes::deployment_server::mediawiki
    include profile::kubernetes::deployment_server::sophroid_config
    include profile::imagecatalog
    include profile::docker::engine
    include profile::docker::ferm
    include profile::docker::prune_old_images
    include profile::airflow_devenv
    include profile::mariadb::client
}
