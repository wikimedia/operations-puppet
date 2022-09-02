# SPDX-License-Identifier: Apache-2.0
# K8s::AdmissionPlugins defines which default admission plugins to disable and
# which additional admission plugins to enable.
#
type K8s::AdmissionPlugins = Struct[{
    Optional[enable] => Array[String],
    Optional[disable] => Array[String],
}]
