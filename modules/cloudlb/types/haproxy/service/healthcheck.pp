# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Healthcheck = Struct[{
    'method'  => Optional[Enum['GET', 'POST', 'HEAD']],
    'path'    => Optional[String[1]],
    'options' => Optional[Array[String[1]]],
}]
