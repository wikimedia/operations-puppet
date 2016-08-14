module Puppet::Parser::Functions
  newfunction(:pdbstatusquery, :type => :rvalue, :doc => "\
    Perform a PuppetDB node status query

    The first argument is the node to get the status for.
    Second argument is optional, if specified only return that specific bit of
    status, one of 'name', 'deactivated', 'catalog_timestamp' and 'facts_timestamp'.

    Returns an array of hashes or a array of strings if second argument is supplied.

    Examples:
    # Get status for foo.example.com
    pdbstatusquery('foo.example.com')
    # Get catalog_timestamp for foo.example.com
    pdbstatusquery('foo.example.com', 'catalog_timestamp')") do |args|

    raise(Puppet::ParseError, "pdbquery(): Wrong number of arguments " +
      "given (#{args.size} for 1 or 2)") if args.size < 1 or args.size > 2

    Puppet::Parser::Functions.autoloader.load(:pdbquery) unless Puppet::Parser::Functions.autoloader.loaded?(:pdbquery)

    node, status = args

    ret = function_pdbquery(["status/nodes/#{node}"])
    if status then
      ret[status]
    else
      ret
    end
  end
end
