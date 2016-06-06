# wmflib

Custom Puppet functions that help you get things done.


## apply_format

`apply_format( string $format, array $items )`

Apply a format string to each element of an array.

### Examples

    $languages = [ 'finnish', 'french', 'greek', 'hebrew' ]
    $packages = apply_format('texlive-lang-%s', $languages)


## conflicts

`conflicts( string|resource $resource )`

Throw an error if a resource is declared.

### Examples

    conflicts('::redis::legacy')
    conflicts(Class['::redis-server'])


## ensure_directory

`ensure_directory( string|bool $ensure )`

Takes a generic 'ensure' parameter value and convert it to an
appropriate value for use with a directory declaration.

If $ensure is 'true' or 'present', the return value is 'directory'.
Otherwise, the return value is the unmodified $ensure parameter.

### Examples

    # Sample class which creates or removes '/srv/redis'
    # based on the class's generic $ensure parameter:
    class redis( $ensure = present ) {
        package { 'redis-server':
            ensure => $ensure,
        }

        file { '/srv/redis':
          ensure => ensure_directory($ensure),
        }
    }


## ensure_link

`ensure_link( string|bool $ensure )`

Takes a generic 'ensure' parameter value and convert it to an
appropriate value for use with a symlink file declaration.

If $ensure is 'true' or 'present', the return value is 'link'.
Otherwise, the return value is the unmodified $ensure parameter.

### Examples

    # Sample class which creates or remove a symlink
    # based on the class's generic $ensure parameter:
    class rsyslog( $ensure = present ) {
        package { 'rsyslog':
            ensure => $ensure,
        }

        file { '/etc/rsyslog.d/50-default.conf':
            ensure => ensure_link($ensure),
            target => '/usr/share/rsyslog/50-default.conf',
        }
    }


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


## ensure_service

`ensure_service( string|bool $ensure )`

Takes a generic 'ensure' parameter value and convert it to an
appropriate value for use with a service declaration.

If $ensure is 'true' or 'present', the return value is 'running'.
Otherwise, the return value is 'stopped'.

### Examples

    # Sample class which starts or stops the redis service
    # based on the class's generic $ensure parameter:
    class redis( $ensure = present ) {
        package { 'redis-server':
            ensure => $ensure,
        }
        service { 'redis':
            ensure  => ensure_service($ensure),
            require => Package['redis-server'],
        }
    }


## hash_deselect_re

`hash_deselect_re( string $regex, hash $input )`

Does exactly the opposite of hash_select_re below: keys matching
the regex are *excluded* from the new hash.


## hash_select_re

`hash_select_re( string $regex, hash $input )`

This creates a new hash from the input hash, but only copies the
keys which match the regex.  In other words, it does the
equivalent of this in Ruby pseudo-code:

  return input.select { |k, _v| regex.match(k) }

### Example

   hash_select_re('^a', {"abc" => 1, "def" => 2, "asdf" => 3})

will produce:

   {"abc" => 1, "asdf" => 3}


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


## os_version

`os_version( string $version_predicate )`

Performs semantic OS version comparison.

Takes one or more string arguments, each containing one or more predicate
expressions. Each expression consts of a distribution name, followed by a
comparison operator, followed by a release name or number. Multiple clauses
are OR'd together. The arguments are case-insensitive.

The host's OS version will be compared to to the comparison target
using the specified operator, returning a boolean. If no operator is
present, the equality operator is assumed.

### Examples

    # True if Ubuntu Trusty or newer or Debian Jessie or newer
    os_version('ubuntu >= trusty || debian >= Jessie')

    # True if exactly Debian Jessie
    os_version('debian jessie')


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


## requires_os

`requires_os( string $version_predicate )`

Validate that the host OS version satisfies a version
check. Abort catalog compilation if not.

See the documentation for os_version() for supported
predicate syntax.

### Examples

    # Fail unless version is Trusty or Jessie
    requires_os('ubuntu trusty || debian jessie')

    # Fail unless Trusty or newer
    requires_os('ubuntu >= trusty')



## shell_exports

`shell_exports( hash $variables [, bool $uppercase_keys = true ] )`

Generate shell environment variable declarations out of a Puppet hash.

The hash keys are used as the variable names, and the values as
the variable's values. Values are automatically quoted with double
quotes. If the second parameter is true (the default), keys are
automatically uppercased.

### Examples

Invocation:

    shell_exports({
        apache_run_user => 'apache',
        apache_pid_file => '/var/run/apache2/apache2.pid',
    })

Output:

    export APACHE_RUN_USER="apache"
    export APACHE_PID_FILE="/var/run/apache2/apache2.pid"


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


## to_milliseconds
`to_milliseconds( string $time_spec )`

Convert a unit of time expressed as a string to milliseconds.

### Examples

    to_milliseconds('1s')        # 1000
    to_milliseconds('1 second')  # 1000


## to_seconds
`to_seconds( string $time_spec )`

Convert a unit of time expressed as a string to seconds.

### Examples

    to_seconds('9000ms')  # 9
    to_seconds('1hr')     # 3600
    to_seconds('2 days')  # 172800


## validate_array_re
`validate_array_re( array $items, string $re )`

Throw an error if any member of $items does not match the regular
expression $re.

### Examples

    # OK -- each array item is a four-digit number.
    validate_array_re([8123, 8124, 8125], '^\d{4}$')

    # Fail -- last array item is not a four-digit number.
    validate_array_re([8123, 8124, 812], '^\d{4}$')


## validate_ensure
`validate_ensure( string $ensure )`

Throw an error if the $ensure argument is not 'present' or 'absent'.

### Examples

    # Abort compilation if $ensure is invalid
    validate_ensure($ensure)
