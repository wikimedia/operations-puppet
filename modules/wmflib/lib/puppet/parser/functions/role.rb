module Puppet::Parser::Functions
  newfunction(:role, :arity => 1) do |args|
    # This will add to the catalog, and to the node specifically:
    # - A global 'role' hash with the 'role::#{arg}' key set to true; if the variable is present, append to it
    # - Include class role::#{arg} if present
    args.flatten do |arg|
      rolename = 'role::' + arg
      rolevar = compiler.topscope.lookupvar('::role')
      if rolevar
        rolevar[rolename] = true
      else
        compiler.topscope.setvar('role', {rolename => true})
      end

      role_class = compiler.topscope.find_hostclass(rolename)
      if !role_class
        raise  "class not in scope"
      else
        send Puppet::Parser::Functions.function(:include), [rolename]
      end
    end
  end
end
