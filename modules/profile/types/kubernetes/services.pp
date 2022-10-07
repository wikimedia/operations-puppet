# SPDX-License-Identifier: Apache-2.0
# == Type: Profile::Kubernetes::Services
#
# Hash containing the description of a kubernetes service for the
# deployment hosts and any host that needs k8s users credentials.
#
#
# [*namespace*] Optional namespace name
#
# [*usernames*] Hash of kubernetes users, with optional unix-level access permissions
#   for kubeconfig files, plust the ability to define the kubeconfig name if different
#   from the username.
#
# [*private_files*] Hash of unix-level access permissions for private helmfile data.
#
type Profile::Kubernetes::Services = Struct[{
    usernames       => Array[Struct[{
        name => String,
        owner => Optional[String],
        group => Optional[String],
        mode  => Optional[String],
        kubeconfig => Optional[String],
    }]],
    namespace       => Optional[String],
    private_files   => Optional[Struct[{'owner' => String, 'group' => String, 'mode' => String, }]]

}]
