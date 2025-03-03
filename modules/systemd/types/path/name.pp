# SPDX-License-Identifier: Apache-2.0
# See systemd.unit(5) for a description of valid names
type Systemd::Path::Name = Pattern[/^[a-zA-Z0-9@:_.\\-]{1,248}\.path$/]
