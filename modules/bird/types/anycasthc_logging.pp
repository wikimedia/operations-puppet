# SPDX-License-Identifier: Apache-2.0
type Bird::Anycasthc_logging = Struct[{
    level       => Wmflib::Syslog::Level::Python,
    num_backups => Integer[1],
}]
