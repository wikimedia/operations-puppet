Puppet::Functions.create_function(:'wmflib::inject_secret') do
  # Injects secrets in a data structure, recursively. It searches string values
  # containing secret(something), and swaps them with the content of the secret
  # parser function. This allows to define hiera with calls to secret() inline,
  # so that it doesn't need to be added to the private hiera repository but
  # to the public one instead. It also guarantees better access control to said secrets.
  # @param Hash datastructure
  # @return Hash the datastructure with the injected secrets
  dispatch :inject_secret do
    param 'Variant[Hash,Array,String]', :data
    return_type 'Variant[Hash,Array,String]'
  end
  def inject_secret(data)
    if data.is_a?Hash
      return data.inject({}) { |h, (k, v)| h[k] = inject_secret(v); h } # rubocop:disable Style/Semicolon
    elsif data.is_a?Array
      return data.map{ |x| inject_secret(x)}
    elsif data.is_a?String
      matches = data.match(/^secret\((.*)\)$/)
      if matches
        return call_function('secret', matches.captures[0])
      end
    end
    data
  end
end
