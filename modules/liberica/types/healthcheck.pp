# SPDX-License-Identifier: Apache-2.0
type Liberica::Healthcheck = Variant[Liberica::HTTPCheck, Liberica::IdleTCPConnectionCheck, Liberica::DNSCheck]
