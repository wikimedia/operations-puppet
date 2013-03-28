[Limn][https://github.com/wikimedia/limn] puppet module.

# Usage

```puppet

# Spawn up a limn instance called 'my-instance'.
# Data files are expected to be at
# /var/lib/limn/my-instance/data.
limn::instance { "my-instance": }

```

Note that the limn class by default does not attempt to install a limn
package.  There is not currently a supported limn .deb package, so we
recommend cloning the [limn repository][https://github.com/wikimedia/limn]
directly into /usr/local/share/limn (or elsewhere if you set base_directory to something non default on limn::instance).  Or deploy limn to wherever you
see fit.


```limn::instance::proxy``` sets up an Apache VirtualHost reverse proxying on port 80. 

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


