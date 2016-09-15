class Hiera
  class Httpcache < Filecache
    def initialize
      super
      require 'httpclient'
      require 'yaml'
      require 'json'
      config = Config[:httpyaml]
      @url_prefix = config[:url_prefix]
      @http = HTTPClient.new(:agent_name => 'HieraHttpCache/0.1')
      @stat_ttl = config[:cache_ttl] || 60
      if defined? @http.ssl_config.ssl_version
        @http.ssl_config.ssl_version = 'TLSv1'
      else
        # Note: this seem to work in later versions of the library,
        # but has no effect. How cute, I <3 ruby.
        @http.ssl_config.options = OpenSSL::SSL::OP_NO_SSLv3
      end
    end

    def read(path, expected_type=Hash, default=nil)
      read_file(path)
    rescue => detail
      # When failing to read data, we raise an exception, see https://phabricator.wikimedia.org/T78408
      error = "Reading data from #{path} failed: #{detail.class}: #{detail}"
      raise error
    end

    def read_file(path)
      if stale?(path)
        data = get_from_http(path)
        @cache[path][:data] = data

        if !@cache[path][:data].is_a?(Object)
          raise TypeError, "Data retrieved from #{path} is #{data.class} not Object"
        end
      end

      @cache[path][:data]
    end

    private

    def stale?(path)
      # We don't actually have caching information lol
      # So we just, uh, blindly cache for 60s
      now = Time.now.to_i
      if @cache[path].nil?
        @cache[path] = {:data => nil, :meta => {:ts => now}}
        return true
      elsif (now - @cache[path][:meta][:ts]) <= @stat_ttl
        # if we already fetched the result within the last stat_ttl seconds,
        # we don't bother killing the mediawiki instance with a flood of requests
        return false
      else
        # This means there's a ts and it's old enough
        @cache[path][:meta][:ts] = now
        return true
      end
    end

    def get_from_http(path)
      url = path.sub('httpyaml/', @url_prefix)
      Hiera.debug("Fetching #{url}")
      res = @http.get(url)
      if res.status_code != 200
        raise IOError, "Could not correctly fetch revision for #{path}, HTTP status code #{res.status_code}, content #{res.data}"
      end
      # We shamelessly throw exceptions here, and catch them upper in the chain
      # specifically in Hiera::Mwcache.stale? and Hiera::Mwcache.read
      # FIXME: use safe_load here somehow?
      body = YAML.load(res.body)

      body['hiera']
    end
  end
end
