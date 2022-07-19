# SPDX-License-Identifier: Apache-2.0

# @type Prometheus::Blackbox::Query_response

# See also https://github.com/prometheus/blackbox_exporter/blob/master/CONFIGURATION.md#tcp_probe
type Prometheus::Blackbox::Query_response = Optional[Array[
  Struct[{
      'send'     => Optional[String[1]],
      'expect'   => Optional[String[1]],
      'starttls' => Optional[Boolean],
  }]
]]
