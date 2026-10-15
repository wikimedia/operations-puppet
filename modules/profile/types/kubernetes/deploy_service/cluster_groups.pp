# SPDX-License-Identifier: Apache-2.0
# == Type: Profile::Kubernetes::Deploy_service::Cluster_groups
#
# The Kubernetes cluster groups that 'scap deploy-service' deploys to, by name.
# A group names its helmfile environments and the stages that an environment
# deploys in.  This is the content of /etc/scap/cluster-groups.yaml.
#
# For a detailed description, consult load_cluster_groups in
# https://gitlab.wikimedia.org/repos/releng/scap/-/blob/master/scap/deploy_service.py
#
type Profile::Kubernetes::Deploy_service::Cluster_groups = Hash[String[1], Struct[{
    # The subdirectory of /srv/deployment-charts/helmfile.d that holds the
    # helmfiles of the group.  The default is "services".
    'dir'                       => Optional[String[1]],
    'environments'              => Hash[String[1], Struct[{
        'datacenter' => String[1],
        'type'       => Enum['STAGING', 'PRODUCTION'],
        # Other names for the environment, for use in the service catalog.
        'aliases'    => Optional[Array[String[1]]],
    }], 1],
    # The order in which the stages of an environment deploy.
    'environment_stages'        => Array[String[1], 1],
    # The stage of a release that names none.  One of environment_stages.
    'environment_default_stage' => String[1],
}]]
