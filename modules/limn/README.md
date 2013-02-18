[Limn][https://github.com/wikimedia/limn] puppet module.

# Usage

```puppet

# Spawn up a limn instance called 'my-instance'.
# Data files are expected to be at
# /var/lib/limn/my-instance/data.
limn::instance { "my-instance": }

```

The above will start a Limn instance listening on port 8081, with an
apache VirtualHost reverse proxying to it on port 80.  If the defaults
for the VirtualHost don't work for you, you can set proxy => false
on the instance and set it up yourself or using the limn::instance::proxy
define.

Note that the limn class by default does not attempt to install a limn
package.  There is not currently a supported limn .deb package, so we
recommend cloning the [limn repository][https://github.com/wikimedia/limn]
directly into /usr/local/share/limn (or elsewhere if you set base_directory to something non default on limn::instance).  Or deploy limn to wherever you
see fit.

## Example:

```bash
# Install Limn at /usr/local/share/limn
sudo git clone https://github.com/wikimedia/limn.git /usr/local/share/limn
```

```puppet

class role::analytics::reportcard {
  # spawn up a limn instance called 'reportcard'
  # using the defaults.
  limn::instance { 'reportcard': }

  # We want an Apache VirtualHost to proxy
  # 'reportcard.wmflabs.org' to the reportcard
  # limn instance.
  limn::instance::proxy { 'reportcard':
    server_name => 'reportcard.wmflabs.org',
    require     => Limn::Instance['reportcard'],
  }
}
```

# Requirements
* puppet-labs' apache puppet module.


