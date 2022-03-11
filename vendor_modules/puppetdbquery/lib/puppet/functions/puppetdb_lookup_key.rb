# The `puppetdb_lookup_key` is a hiera 5 `lookup_key` data provider function.
# See (https://docs.puppet.com/puppet/latest/hiera_custom_lookup_key.html) for
# more info.
#
# See README.md#hiera-backend for usage.
#
Puppet::Functions.create_function(:puppetdb_lookup_key) do

  dispatch :puppetdb_lookup_key do
    param 'String[1]', :key
    param 'Hash[String[1],Any]', :options
    param 'Puppet::LookupContext', :context
  end

  def puppetdb_lookup_key(key, options, context)
    return context.cached_value(key) if context.cache_has_key(key)

    if !key.end_with?('::_nodequery') && nodequery = call_function('lookup', "#{key}::_nodequery", 'merge' => 'first', 'default_value' => nil)
      # Support specifying the query in a few different ways
      query, fact, sort = case nodequery
                          when Hash then [nodequery['query'], nodequery['fact'], nodequery['sort']]
                          when Array then nodequery
                          else [nodequery.to_s, nil, nil]
                          end

      paramz = [query, fact].compact
      result = call_function('query_nodes', *paramz)
      result.sort! if sort
      context.cache(key, result)
    else
      context.not_found
    end
  end
end
