# SPDX-License-Identifier: Apache-2.0
define loopio::dev (
  String $size,
  String $devname = $title,
) {
  require loopio::init

  $backing_file = "/var/lib/loopio/${devname}"

  exec { "create backing file for ${devname}":
      creates => $backing_file,
      command => "/usr/bin/truncate --size ${size} ${backing_file}",
  }

  service { "loopio@${devname}.service":
      ensure => running,
      enable => true,
  }

}
