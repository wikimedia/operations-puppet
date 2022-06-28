# SPDX-License-Identifier: Apache-2.0
  type Gitlab_runner::AllowedService = Struct[{
    port  => Stdlib::Port,
    host  => Stdlib::Host,
    proto => Optional[Enum['tcp', 'udp']],
  }]
