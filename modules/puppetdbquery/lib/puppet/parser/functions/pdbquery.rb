module Puppet::Parser::Functions
  newfunction(:pdbquery, :type => :rvalue, :doc => "\
    Perform a PuppetDB query

    The first argument is the URL path that should be queried, for
    example 'nodes' or 'status/nodes/<nodename>'.
    The second argument if supplied if the query parameter, if it is
    a string it is assumed to be JSON formatted and sent as is,
    anything else is converted to JSON and then sent.

    Example: pdbquery('nodes', ['=', ['node', 'active'], true ])") do |args|

    raise(Puppet::ParseError, "pdbquery(): Wrong number of arguments " +
      "given (#{args.size} for 1 or 2)") if args.size < 1 or args.size > 2

    require 'puppet/network/http_pool'
    require 'uri'
    require 'puppet/util/puppetdb'
    require 'puppet/indirector/rest'

    # Query type (URL path)
    t, q = args

    # Query contents
    if q then
      # Convert to JSON if it isn't already
      q=q.to_pson unless q.is_a? String
      params = URI.escape("?query=#{q}")
    else
      params = ''
    end

    conn = Puppet::Network::HttpPool.http_instance(Puppet::Util::Puppetdb.server, Puppet::Util::Puppetdb.port, use_ssl = true)
    response = conn.get("/v1/#{t}#{params}", { "Accept" => "application/json",})

    unless response.kind_of?(Net::HTTPSuccess)
      raise Puppet::ParseError, "PuppetDB query error: [#{response.code}] #{response.msg}"
    end
    PSON.load(response.body)
  end
end
