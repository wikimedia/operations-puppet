# SPDX-License-Identifier: Apache-2.0
type Profile::Syslog::Hosts = Hash[
    Variant[Enum['default'], Wmflib::Sites],
    Array[String[1], 1]
]
