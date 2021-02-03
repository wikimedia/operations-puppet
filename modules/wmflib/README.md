# wmflib

Custom Puppet functions and types that help you get things done.

# Types

## Wmflib::Ensure
Accepts either 'present' or 'absent' as values.
Should be used to validate standard ensure parameters

# Functions

## conflicts

`conflicts( string|resource $resource )`

Throw an error if a resource is declared.

### Examples

    conflicts('::redis::legacy')
    conflicts(Class['::redis-server'])

## ensure_mounted

`ensure_mounted( string|bool $ensure )`

Takes a generic `ensure` parameter value and convert it to an
appropriate value for use with a mount declaration.

If `$ensure` is `true` or `present`, the return value is `mounted`.
Otherwise, the return value is the unmodified `$ensure` parameter.

### Examples

    # Sample class which mounts or unmounts '/var/lib/nginx'
    # based on the class's generic $ensure parameter:
    class nginx ( $ensure = present ) {
        package { 'nginx-full':
            ensure => $ensure,
        }
        mount { '/var/lib/nginx':
            ensure  => ensure_mounted($ensure),
            device  => 'tmpfs',
            fstype  => 'tmpfs',
            options => 'defaults,noatime,uid=0,gid=0,mode=755,size=1g',
        }
    }


## ini

`ini( hash $ini_settings [, hash $... ] )`

Serialize a hash into the .ini-style format expected by Python's
ConfigParser. Takes one or more hashes as arguments. If the argument
list contains more than one hash, they are merged together. In case of
duplicate keys, hashes to the right win.

### Example

    ini({'server' => {'port' => 80}})

will produce:

    [server]
    port = 80


## ordered_json

`ordered_json( hash $data [, hash $... ] )`

Serialize a hash into JSON with lexicographically sorted keys.

Because the order of keys in Ruby 1.8 hashes is undefined, 'to_pson'
is not idempotent: i.e., the serialized form of the same hash object
can vary from one invocation to the next. This causes problems
whenever a JSON-serialized hash is included in a file template,
because the variations in key order are picked up as file updates by
Puppet, causing Puppet to replace the file and refresh dependent
resources on every run.

### Examples

    # Render a Puppet hash as a configuration file:
    $options = { 'useGraphite' => true, 'minVal' => '0.1' }
    file { '/etc/kibana/config.json':
        content => ordered_json($options),
    }


## ordered_yaml

`ordered_yaml( mixed $data )`

Emit a hash as YAML with keys (both shallow and deep) in sorted order.

### Examples

    # Render a Puppet hash as a configuration file:
    $options = { 'useGraphite' => true, 'minVal' => '0.1' }
    file { '/etc/kibana/config.yaml':
        content => ordered_yaml($options),
    }


## php_ini

`php_ini( hash $ini_settings [, hash $... ] )`

Serialize a hash into php.ini-style format. Takes one or more hashes as
arguments. If the argument list contains more than one hash, they are
merged together. In case of duplicate keys, hashes to the right win.

### Example

    php_ini({'server' => {'port' => 80}}) # => server.port = 80


## require_package

`require_package( string $package_name [, string $... ] )`

Declare one or more packages a dependency for the current scope.
This is equivalent to declaring and requiring the package resources.
In other words, it ensures the package(s) are installed before
evaluating any of the resources in the current scope.

### Examples

    # Single package
    require_package('python-redis')

    # Multiple packages as arguments
    require_package('redis-server', 'python-redis')

    # Multiple packages as array
    $deps = [ 'redis-server', 'python-redis' ]
    require_package($deps)


## requires_realm

`requires_realm( string $realm, [ string $message ] )`

Validate that the host realm is equal to some value.
Abort catalog compilation if it is not.

### Examples

    # Fail unless running in Labs:
    requires_realm('labs')


## ssl_ciphersuite

`ssl_ciphersuite( string $servercode, string $encryption_type, boolean $hsts )`

Outputs the ssl configuration directives for use with either Nginx
or Apache using our selection of ciphers and SSL options.

Takes three arguments:

- The server to configure for: 'apache' or 'nginx'
- The compatibility mode,indicating the degree of compatibility we
  want to retain with older browsers (basically, IE6, IE7 and
  Android prior to 3.0)
- hsts - optional boolean, true emits our standard public HSTS

Whenever called, this function will output a list of strings that
can be safely used in your configuration file as the ssl
configuration part.

### Examples

    ssl_ciphersuite('apache', 'compat', true)
    ssl_ciphersuite('nginx', 'strong')
