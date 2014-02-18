
class role::labs::tools {

  class config {
    include role::labsnfs::client # temporary measure

    $grid_master = "tools-master.pmtpa.wmflabs"
  }

  class bastion inherits role::labs::tools::config {
    system::role { "role::labs::tools::bastion": description => "Tool Labs bastion" }
    class { 'toollabs::bastion':
      gridmaster => $grid_master,
    }
  }

  class execnode inherits role::labs::tools::config {
    system::role { "role::labs::tools::execnode": description => "Tool Labs execution host" }
    class { 'toollabs::execnode':
      gridmaster => $grid_master,
    }
    class { 'imagescaler::packages::fonts': }
  }

  class webnode inherits role::labs::tools::config {
    system::role { "role::labs::tools::webnode": description => "Tool Labs clustered web host" }
    class { 'toollabs::webnode':
      gridmaster => $grid_master,
    }
  }

  class master inherits role::labs::tools::config {
    system::role { "role::labs::tools::master": description => "Tool Labs gridengine master" }
    class { 'toollabs::master': }
  }

  class shadow inherits role::labs::tools::config {
    system::role { "role::labs::tools::shadow": description => "Tool Labs gridengine shadow (backup) master" }
    class { 'toollabs::shadow':
      gridmaster => $grid_master,
    }
  }

  class webserver inherits role::labs::tools::config {
    system::role { "role::labs::tools::webserver": description => "Tool Labs webserver" }
    class { 'toollabs::webserver':
      gridmaster => $grid_master,
    }
  }

  class webproxy inherits role::labs::tools::config {
    system::role { "role::labs::tools::webproxy": description => "Tool Labs web proxy" }
    include toollabs::webproxy
  }

  class proxy inherits role::labs::tools::config {
      system::role { "role::labs::tools::proxy": description => "Tool labs generic web proxy" }
      include toollabs::proxy
  }

  class mailrelay inherits role::labs::tools::config {
    system::role { "role::labs::tools::mailrelay": description => "Tool Labs mail relay" }
    class { 'toollabs::mailrelay':
      maildomain => "tools.wmflabs.org",
    }
  }

  class syslog inherits role::labs::tools::config {
    system::role { "role::labs::tools::syslog": description => "Central logging server for tools and services" }
    class { 'toollabs::syslog': }
  }

  class redis inherits role::labs::tools::config {
    system::role { "role::labs::tools::redis": description => "Server that hosts shared Redis instance" }
    class { 'toollabs::redis':
      maxmemory => $::redis_maxmemory
    }
  }

} # class role::labs::tools

