#
# This is a nice generic place to make project-specific roles with a sane
# naming scheme.
#

class role::labs::tools {

  class config {
    include role::labsnfs::client # temporary measure

    $grid_master = "tools-master.pmtpa.wmflabs"
  }

  class bastion inherits role::labs::tools::config {
    system_role { "role::labs::tools::bastion": description => "Tool Labs bastion" }
    class { 'toollabs::bastion':
      gridmaster => $grid_master,
    }
  }

  class execnode inherits role::labs::tools::config {
    system_role { "role::labs::tools::execnode": description => "Tool Labs execution host" }
    class { 'toollabs::execnode':
      gridmaster => $grid_master,
    }
  }

  class master inherits role::labs::tools::config {
    system_role { "role::labs::tools::master": description => "Tool Labs gridengine master" }
    class { 'toollabs::master': }
  }

  class shadow inherits role::labs::tools::config {
    system_role { "role::labs::tools::shadow": description => "Tool Labs gridengine shadow (backup) master" }
    class { 'toollabs::shadow':
      gridmaster => $grid_master,
    }
  }

  class webserver inherits role::labs::tools::config {
    system_role { "role::labs::tools::webserver": description => "Tool Labs webserver" }
    class { 'toollabs::webserver':
      gridmaster => $grid_master,
    }
  }

  class webproxy inherits role::labs::tools::config {
    system_role { "role::labs::tools::webproxy": description => "Tool Labs web proxy" }
    class { 'toollabs::webproxy': }
  }

  class mailrelay inherits role::labs::tools::config {
    system_role { "role::labs::tools::mailrelay": description => "Tool Labs mail relay" }
    class { 'toollabs::mailrelay':
      maildomain => "toollabs.org",
    }
  }

} # class role::labs::tools

