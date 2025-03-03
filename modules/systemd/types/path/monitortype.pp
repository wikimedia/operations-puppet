# SPDX-License-Identifier: Apache-2.0
# Defines a systemd path unit monitor type
# See systemd.path(5) for a description of valid types
type Systemd::Path::MonitorType = Enum['PathExists', 'PathExistsGlob', 'PathChanged', 'PathModified', 'DirectoryNotEmpty']
