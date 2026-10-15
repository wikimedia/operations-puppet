# SPDX-License-Identifier: Apache-2.0
# == Type: Profile::Kubernetes::Deploy_service::Service_catalog
#
# The services that 'scap deploy-service' deploys, and the helmfile releases
# that each one deploys.  This is the content of
# /etc/scap/service-catalog.yaml.
#
# The commented-out example service in
# hieradata/role/common/deployment_server/kubernetes.yaml describes each key.
#
type Profile::Kubernetes::Deploy_service::Service_catalog = Struct[{
    'services' => Optional[Hash[String[1], Struct[{
        # A cluster group of
        # profile::kubernetes::deployment_server::deploy_service::cluster_groups.
        'cluster_group' => String[1],
        'namespaces'    => Hash[String[1], Struct[{
            # An entry is an environment name, or a mapping of one environment
            # name to its body.
            'environments' => Array[Variant[
                String[1],
                Hash[String[1], Optional[Struct[{
                    'releases' => Optional[Profile::Kubernetes::Deploy_service::Releases],
                }]], 1, 1],
            ], 1],
        }], 1],
        # The checks to run, by environment name and then by stage name.
        'checks'        => Optional[Hash[String[1], Hash[String[1], Array[Variant[
            Struct[{'commands' => Array[String[1], 1]}],
            Struct[{'manual' => Optional[String[1]]}],
        ]]]]],
    }], 1]],
}]
