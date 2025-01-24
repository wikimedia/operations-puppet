# SPDX-License-Identifier: Apache-2.0
# Liberica forwarding plane daemon config
# [*log_level*]
#  log level
# [*grpc*]
#  grpc config, it will be used as listener config by the forwarding plane daemon
#  and as client config by the control plane daemon
# [*prometheus*]
#  prometheus endpoint configuration
# [*forwarding_plane*]
#  Forwarding plane used to balance the traffic (ipvs, katran)
# [*katran*]
#  Katran specific configuration
type Liberica::FpConfig = Struct[{
        'log_level'        => Liberica::Logging,
        'grpc'             => Liberica::Grpc,
        'prometheus'       => Liberica::Prometheus,
        'forwarding_plane' => Enum['ipvs', 'katran'],
        'katran'           => Optional[Liberica::Katran],
}]
