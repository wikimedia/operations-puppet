# == Function: wmflib::php_ini( hash $ini_settings [, hash $... ] )
#
# Serialize a hash into php.ini-style format. Takes one or more hashes
# as arguments. If the argument list contains more than one hash, they
# are merged together. In case of duplicate keys, hashes to the right
# win.
#
# === Example
#
#   wmflib::php_ini({'server' => {'port' => 80}}) # => server.port = 80
#
Puppet::Functions.create_function(:'wmflib::php_ini') do
  dispatch :php_ini do
    required_repeated_param "Hash", :data
    return_type "String"
  end

  def php_ini(*args)
    flat = args.map { |arg| ini_flatten(arg) }.inject(:merge)
    options = flat.map do |k, vs|
      case vs
      when Array then vs.map { |v| "#{k}[#{v}] = #{ini_cast(v)}" }
      else "#{k} = #{ini_cast(vs)}"
      end
    end
    options.flatten.sort.push("").join("\n")
  end

  def ini_flatten(map, prefix = nil)
    map.reduce({}) do |flat, (k, v)|
      k = [prefix, k].compact.join(".")
      flat.merge! v.is_a?(Hash) ? ini_flatten(v, k) : Hash[k, v]
    end
  end

  def ini_cast(v)
    v.include?(".") ? Float(v) : Integer(v)
  rescue
    v
  end
end
