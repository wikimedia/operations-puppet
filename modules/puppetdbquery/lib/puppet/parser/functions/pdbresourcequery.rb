module Puppet::Parser::Functions
  newfunction(:pdbresourcequery, :type => :rvalue, :doc => "\
    Perform a PuppetDB resource query

    The first argument is the resource query, it has to be an array.
    Second argument is optional but allows you to specify the item you want
    from the returned hash.

    This function excludes any deactivated hosts.

    Returns an array of hashes or array of strings if second argument is provided.

    Examples:
    # Return an array of hashes describing all files that are owned by root on active hosts.
    $ret = pdbresourcequery(
      ['and',
        ['=','type','File'],
        ['=',['parameter','owner'],'root']])

    # Return an array of host names having those resources
    $ret = pdbresourcequery(
      ['and',
        ['=','type','File'],
        ['=',['parameter','owner'],'root']], 'certname')") do |args|

    raise(Puppet::ParseError, "pdbresourcequery(): Wrong number of arguments " +
                "given (#{args.size} for 1 or 2)") if args.size < 1 or args.size > 2

    Puppet::Parser::Functions.autoloader.load(:pdbquery) unless Puppet::Parser::Functions.autoloader.loaded?(:pdbquery)

    resq, info = args
    ret = function_pdbquery(['resources', ['and',['=',['node','active'],true],resq] ])
    if info then
      ret.collect {|x| x[info]}
    else
      ret
    end
  end
end
