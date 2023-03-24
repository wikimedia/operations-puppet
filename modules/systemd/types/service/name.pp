# SPDX-License-Identifier: Apache-2.0
# Per systemd.unit(5):
# Valid unit names consist of a "name prefix" and a dot and a suffix specifying the unit type.
# The "unit prefix" must consist of one or more valid characters (ASCII letters, digits, ":", "-",
# "_", ".", and "\"). The total length of the unit name including the suffix must not exceed
# 256 characters.
type Systemd::Service::Name = Pattern[/^[a-zA-Z0-9@:_.\\-]{1,248}\.service$/]
