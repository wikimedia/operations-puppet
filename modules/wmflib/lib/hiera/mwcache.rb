class Hiera
  class Mwcache < Hiera::Filecache
    def initialize
      super
      require 'httpclient'
      require 'yaml'
      require 'json'
      config = Config[:mwyaml]
      @httphost = config[:host] || 'wikitech.wikimedia.org'
      @endpoint = config[:endpoint] || '/w/api.php'
      @http = HTTPClient.new(:agent_name => 'HieraMwCache/0.1')
      @stat_ttl = config[:cache_ttl] || 60
      #TODO: httpclient on precise may not support 1.2
      @http.ssl_config.ssl_version = 'TLSv1_2'
    end

    def read_file(path, expected_type = Object, &block)
      if stale?(path)
        resp = @http.get("https://#{httphost}#{endpoint}?titles=#{path}&action=query&format=json")
        if resp.status_code == '200'
          data = JSON.parse(resp.body)
          @cache[path][:data] = block_given? ? yield(data) : data
        end
        if !@cache[path][:data].is_a?(expected_type)
          raise TypeError, "Data retrieved from #{path} is #{data.class} not #{expected_type}"
        end
      end

      @cache[path][:data]
    end

    private

    def stale?(path)
      # Performs a request for the revision only
      meta = path_metadata(path)

      if @cache[path][:meta].nil?
        @cache[path][:meta] = meta
        return true
      end
      if @cache[path][:meta][:revision] == meta[:revision]
        @cache[path][:meta][:ts] = meta[:ts]
        return false
      else
        @cache[path][:meta] = meta
        return true
      end
    rescue => detail
      error = "Retreiving metadata from ${path} failed: #{detail}"
      Hiera.debug(error)
      # Fill  this up with very safe defaults
      @cache[path][:meta] = {:ts => 0, :revision => 0}
      return true
    end

    def path_metadata(path)
      now = Time.now.to_i
      if @cache[path].nil?
        @cache[path] = {:data => nil, :meta => nil}
      elsif (now - @cache[path][:meta][:ts]) <= @stat_ttl
        # if we already fetched the result within the last stat_ttl seconds,
        # we don't bother killing the mediawiki instance with a flood of requests
        return @cache[path][:meta]
      end
      # TODO: add some locking mechanism for requests? Maybe overkill, maybe not.
      res = @http.get("#{httphost}#{endpoint}?labsproject=#{path}&gimme_revid_only=1")
      if res.status_code == 200
        return {:ts => now, :revision => res.http_body}
      else
        raise IOError, "Could not correctly fetch revision for #{path}, HTTP status code #{res.status_code}"
      end
    end
  end
end
