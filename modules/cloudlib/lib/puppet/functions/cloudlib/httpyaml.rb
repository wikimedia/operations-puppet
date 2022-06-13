# SPDX-License-Identifier: Apache-2.0
Puppet::Functions.create_function(:'cloudlib::httpyaml') do
  require 'net/http'
  require 'uri'
  require 'yaml'
  dispatch :data_hash do
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end
  def data_hash(options, context)
    uri = URI.parse(options['uri'])
    path = URI.escape(context.interpolate(uri.request_uri))
    if context.cache_has_key(path)
      context.explain { "Returning cached value for #{path}" }
      value = context.cached_value(path)
      return value
    else
      context.explain { "Querying #{uri}" }
      if context.cache_has_key('__http_handler')
        http_handler = context.cached_value('__http_handler')
      else
        http_handler = Net::HTTP.new(uri.host, uri.port)
        context.cache('__http_handler', http_handler)
      end
      request = Net::HTTP::Get.new(path)
      begin
        response = http_handler.request(request)
        body = YAML.safe_load(response.body)
        value = body.fetch('hiera', {})
        context.cache(path, value)
        return value
      rescue StandardError => e
        raise Puppet::DataBinding::LookupError, "cloudlib::httpyaml failed #{e.message}"
      end
    end
  end
end
