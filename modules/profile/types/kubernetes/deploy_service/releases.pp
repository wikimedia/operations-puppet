# SPDX-License-Identifier: Apache-2.0
# == Type: Profile::Kubernetes::Deploy_service::Releases
#
# The releases of one helmfile environment that 'scap deploy-service' deploys.
# An entry is a release name, or a mapping of one release name to its body.
# Omit the key to deploy every release of the environment.
#
# The commented-out example service in
# hieradata/role/common/deployment_server/kubernetes.yaml describes each key.
#
type Profile::Kubernetes::Deploy_service::Releases = Array[Variant[
    String[1],
    # 'stage' is one of the environment_stages of the cluster group.
    Hash[String[1], Optional[Struct[{'stage' => Optional[String[1]]}]], 1, 1],
], 1]
