# SPDX-License-Identifier: Apache-2.0

# Represent a generic logging level
type  Wmflib::Syslog::Level = Variant[
    Wmflib::Syslog::Level::Python,
    Wmflib::Syslog::Level::Log4j,
    Wmflib::Syslog::Level::Unix,
]
