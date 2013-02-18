[Limn][https://github.com/wikimedia/limn] puppet module.

# Usage

```puppet

# Spawn up a limn instance called 'my-instance'.
# Data files are expected to be at
# /var/lib/limn/my-instance/data.
limn::instance { "my-instance":
  $port           = 8081,
}

```
