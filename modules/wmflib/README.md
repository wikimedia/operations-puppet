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

## wmflib::ini

`wmflib::ini( hash $ini_settings [, hash $... ] )`

Serialize a hash into the .ini-style format expected by Python's
ConfigParser. Takes one or more hashes as arguments. If the argument
list contains more than one hash, they are merged together. In case of
duplicate keys, hashes to the right win.

### Example

    wmflib::ini({'server' => {'port' => 80}})

will produce:

    [server]
    port = 80


## wmflib::php_ini

`wmflib::php_ini( hash $ini_settings [, hash $... ] )`

Serialize a hash into php.ini-style format. Takes one or more hashes as
arguments. If the argument list contains more than one hash, they are
merged together. In case of duplicate keys, hashes to the right win.

### Example

    wmflib::php_ini({'server' => {'port' => 80}}) # => server.port = 80


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
