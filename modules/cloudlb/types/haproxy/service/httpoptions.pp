# SPDX-License-Identifier: Apache-2.0
# @summary http-specific cloudlb service options
type CloudLB::HAProxy::Service::HTTPOptions = Struct[{
  require_host   => Optional[Stdlib::Fqdn],
  set_headers    => Optional[Hash[String[1], String[1]]],
  timeout_server => Optional[Pattern[/\d+s/]],
}]
