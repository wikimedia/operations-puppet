module Puppet::Parser::Functions
  newfunction(:pdbnodequery_all, :type => :rvalue, :doc => "\
    Perform a PuppetDB node query

    The first argument is the node query.
    Second argument is optional but allows you to specify a resource query
    that the nodes returned also have to match.

    Returns a array of strings with the certname of the nodes (fqdn by default).

    # Return an array of both active and deactivaded nodes with an uptime more than 30 days
    $ret = pdbnodequery_all(['and',['>',['fact','uptime_days'],30]])

    # Return an array of both active and deactivated nodes with an uptime more
    # than 30 days and having the class 'apache'
    $ret = pdbnodequery_all(
      ['>',['fact','uptime_days'],30],
      ['and',
        ['=','type','Class'],
        ['=','title','Apache']])") do |args|

    raise(Puppet::ParseError, "pdbquery_all(): Wrong number of arguments " +
                "given (#{args.size} for 1 or 2)") if args.size < 1 or args.size > 2

    Puppet::Parser::Functions.autoloader.load(:pdbquery) unless Puppet::Parser::Functions.autoloader.loaded?(:pdbquery)
    Puppet::Parser::Functions.autoloader.load(:pdbresourcequery_all) unless Puppet::Parser::Functions.autoloader.loaded?(:pdbresourcequery_all)

    nodeq, resq = args

    nodeqnodes = function_pdbquery(['nodes', nodeq])

    if resq then
      resqnodes = function_pdbresourcequery_all([resq, 'certname'])
      nodeqnodes & resqnodes
    else
      # No resource query to worry about, just return the nodequery
      nodeqnodes
    end
  end
end
