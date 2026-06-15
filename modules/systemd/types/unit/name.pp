# SPDX-License-Identifier: Apache-2.0
type Systemd::Unit::Name = Variant[Systemd::Service::Name, Systemd::Timer::Name, Systemd::Path::Name, Systemd::Mount::Name]
