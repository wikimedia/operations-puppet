# == profile::ci::pipeline::builder
#
# Pipeline server that can build and test Docker images.
#
class profile::ci::pipeline::builder {
    include ::profile::ci::docker

    require_package('helm')
    require_package('kubernetes-client')
    require_package('python3-ruamel.yaml')
}
