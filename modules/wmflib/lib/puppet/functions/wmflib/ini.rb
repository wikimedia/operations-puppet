# == Function: wmflib::ini( hash $ini_settings [, hash $... ] )
#
# Serialize a hash into the .ini-style format expected by Python's
# ConfigParser. Takes one or more hashes as arguments. If the argument
# list contains more than one hash, they are merged together. In case of
# duplicate keys, hashes to the right win.
#
# === Example
#
#   wmflib::ini({'server' => {'port' => 80}})
#
# will produce:
#
#   [server]
#   port = 80
#
Puppet::Functions.create_function(:'wmflib::ini') do
  dispatch :ini do
    required_repeated_param "Hash", :data
    return_type "String"
  end

  def ini(*args)
    args.reduce(&:merge).map do |section, items|
      ini_flatten(items).map do |k, vs|
        case vs
        when Array then vs.map { |v| "#{k}[#{v}] = #{ini_cast(v)}" }
        else "#{k} = #{ini_cast(vs)}"
        end
      end.flatten.sort.push("").unshift("[#{section}]").join("\n")
    end.flatten.sort.push("").join("\n")
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
