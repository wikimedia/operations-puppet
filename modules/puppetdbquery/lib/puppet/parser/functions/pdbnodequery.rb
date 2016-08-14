module Puppet::Parser::Functions
  newfunction(:pdbnodequery, :type => :rvalue, :doc => "\
    Perform a PuppetDB node query

    The first argument is the node query, it has to be an array.
    Second argument is optional but allows you to specify a resource query
    that the nodes returned also have to match.

    This function excludes any deactivated hosts.

    Returns a array of strings with the certname of the nodes (fqdn by default).

    # Return an array of active nodes with an uptime more than 30 days
    $ret = pdbnodequery(['>',['fact','uptime_days'],30])

    # Return an array of active nodes with an uptime more than 30 days and
    # having the class 'apache'
    $ret = pdbnodequery(['>',['fact','uptime_days'],30], ['and',['=','type','Class'],['=','title','Apache']])") do |args|

    raise(Puppet::ParseError, "pdbquery(): Wrong number of arguments " +
                "given (#{args.size} for 1 or 2)") if args.size < 1 or args.size > 2

    Puppet::Parser::Functions.autoloader.load(:pdbquery) unless Puppet::Parser::Functions.autoloader.loaded?(:pdbquery)
    Puppet::Parser::Functions.autoloader.load(:pdbresourcequery) unless Puppet::Parser::Functions.autoloader.loaded?(:pdbresourcequery)

    nodeq, resq = args

    nodeqnodes = function_pdbquery(['nodes', ['and',['=',['node','active'],true],nodeq] ])

    if resq then
      resqnodes = function_pdbresourcequery([resq, 'certname'])
      nodeqnodes & resqnodes
    else
      # No resource query to worry about, just return the nodequery
      nodeqnodes
    end
  end
end
