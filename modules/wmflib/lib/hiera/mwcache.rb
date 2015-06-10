class Hiera
  class MediawikiPageNotFoundError < Exception
  end

  class Mwcache < Filecache
    def initialize
      super
      require 'httpclient'
      require 'yaml'
      require 'json'
      config = Config[:mwyaml]
      @httphost = config[:host] || 'https://wikitech.wikimedia.org'
      @endpoint = config[:endpoint] || '/w/api.php'
      @http = HTTPClient.new(:agent_name => 'HieraMwCache/0.1')
      @stat_ttl = config[:cache_ttl] || 60
      if defined? @http.ssl_config.ssl_version
        @http.ssl_config.ssl_version = 'TLSv1'
      else
        # Note: this seem to work in later versions of the library,
        # but has no effect. How cute, I <3 ruby.
        @http.ssl_config.options = OpenSSL::SSL::OP_NO_SSLv3
      end
    end

    def read(path, expected_type, default=nil, &block)
      read_file(path, expected_type, &block)
    rescue Hiera::MediawikiPageNotFoundError => detail
      # Any errors other than this will cause hiera to raise an error and puppet to fail.
      Hiera.debug("Page #{detail} is non-existent, setting defaults #{default}")
      @cache[path][:data] = default
    rescue => detail
      # When failing to read data, we raise an exception, see https://phabricator.wikimedia.org/T78408
      error = "Reading data from #{path} failed: #{detail.class}: #{detail}"
      raise error
    end

    def read_file(path, expected_type = Object, &block)
      if stale?(path)
        resp = get_from_mediawiki(path, true)
        data = resp["*"]
        @cache[path][:data] = block_given? ? yield(data) : data

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
    rescue Hiera::MediawikiPageNotFoundError => detail
      # Any errors other than this will cause hiera to raise an error and puppet to fail.
      error = "Page #{detail} is non-existent"
      Hiera.warn(error)
      # Fill  this up with very safe defaults - we cache non-existence
      # for cache_ttl as well.
      @cache[path][:meta] = {:ts => Time.now.to_i, :revision => 0}
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
      revision = get_from_mediawiki(path, false)["revid"]

      return {:ts => now, :revision => revision}
    end


    def get_from_mediawiki(path,want_content)
      what = want_content ? 'content' : 'ids'
      query_string = "action=query&prop=revisions&format=json&rvprop=#{what}&titles=Hiera:#{path}"
      url = "#{@httphost}#{@endpoint}?#{query_string}"
      Hiera.debug("Fetching #{url}")
      res = @http.get(url)
      if res.status_code != 200
        raise IOError, "Could not correctly fetch revision for #{path}, HTTP status code #{res.status_code}"
      end
      # We shamelessly throw exceptions here, and catch them upper in the chain
      # specifically in Hiera::Mwcache.stale? and Hiera::Mwcache.read
      body = JSON.parse(res.body)
      pages = body["query"]["pages"]
      # Quoting Yuvi: "MediaWiki API doesn't give a fuck about HTTP status codes"
      if pages.keys.include? "-1"
        raise Hiera::MediawikiPageNotFoundError, "Hiera:#{path}"
      end
      #yes, it's that convoluted.
      key = pages.keys[0]
      return pages[key]["revisions"][0]
    end
  end
end
