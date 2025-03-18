# SPDX-License-Identifier: Apache-2.0
# Excluding QUIC here cause the current puppetization doesn't support Katran as forwarding plane
type Liberica::Protocol = Enum['tcp', 'udp']
