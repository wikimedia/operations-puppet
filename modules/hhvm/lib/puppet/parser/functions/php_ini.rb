# == Function: php_ini
#
# Serialize a hash into php.ini-style format. Takes one or more hashes
# as arguments. If the argument list contains more than one hash, they
# are merged together. In case of duplicate keys, hashes to the right
# win.
#
# === Example
#
#   php_ini({'server' => {'port' => 80}}) # => server.port = 80
#

def flatten_map(map, prefix=nil)
    map.inject({}) do |flat,(k,v)|
        k = [prefix, k].compact.join('.')
        v = v.include?('.') ? Float(v) : Integer(v) rescue v
        flat.merge! v.is_a?(Hash) ? flatten_map(v, k) : Hash[k, v]
    end
end

module Puppet::Parser::Functions
  newfunction(
    :php_ini,
    :type => :rvalue,
    :doc  => <<-END
      Serialize a hash into php.ini-style format. Takes one or more hashes
      as arguments. If the argument list contains more than one hash, they
      are merged together. In case of duplicate keys, hashes to the right
      win.

      Example:

         php_ini({'server' => {'port' => 80}}) # => server.port = 80

    END
  ) do |args|
    fail 'php_ini() operates on hashes' if args.map(&:class).uniq != [Hash]
    args.map { |arg| flatten_map(arg) }.
         inject(:merge).
         sort.
         map { |kv| kv.join(' = ') }.
         push('').
         join("\n")
  end
end
