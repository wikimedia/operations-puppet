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
directly into /usr/lib/limn (or elsewhere if you set base_directory to something non default on limn::instance).

## Examples:

```bash
# Install Limn at /usr/lib/limn
sudo git clone https://github.com/wikimedia/limn.git /usr/lib/limn
```

```puppet
# If this runs in production, the Apache VirtualHost will
# automatically set its ServerName to reportcard.wikimedia.org.
# If this runs in labs, the ServerName will be reportcard.wmflabs.org.
class role::analytics::reportcard {
  limn::instance { "reportcard": }
}
```

```puppet
# If elsewhere, the ServerName will default to reportcard.  In this case, you
# should probably disable automatic proxy setup on the limn::instance, and
# use limn::instance::proxy define manually.
class role::analytics::reportcard {
  # set up the 'reportcard' limn instance without
  # the Apache proxy.
  limn::instance { 'reportcard':
    proxy => false,
  }
  # Set up the Apache proxy with
  # customizations.
  limn::instance::proxy { 'reportcard':
    servername    => 'reportcard.mydomain.org',
    serveraliases => ['reportcard.mydomain.com'],
    require       => Limn::Instance['reportcard'],
  }
}
```

# Requirements
* puppet-labs' apache puppet module.


