# SPDX-License-Identifier: Apache-2.0
# Liberica control plane daemon config
# [*log_level*]
#  log level
# [*grpc*]
#  grpc config, it will be used as listener config by the control plane daemon
#  and as client config by liberica CLI
# [*prometheus*]
#  prometheus endpoint configuration
type Liberica::CpConfig = Struct[{
        'log_level'  => Liberica::Logging,
        'grpc'       => Liberica::Grpc,
        'prometheus' => Liberica::Prometheus,
}]
