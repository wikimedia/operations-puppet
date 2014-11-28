# == Function: role ( string $role_name [, string $... ] )
#
# Declare the _roles variable (or add keys to it), and if the role class
# role::$role_name is in the scope, include it. This is roughly a
# shortcut for
#
# $role[foo] = true
# include role::foo
#
# and has the notable advantage over that that it won't trigger a
# deprecation warning on newer puppet versions. Also, this function
# will refuse to run anywhere but at the node scope, thus making any
# additional role added to a node explicit.
#
# This function is very useful with our "role" hiera backend if you
# have global configs that are role-based
#
# === Example
#
# node /^www\d+/ {
#     include ::admin
#     role mediawiki::appserver  # this will load the role::mediawiki::appserver class
# }


module Puppet::Parser::Functions
  newfunction(:role, :arity => 1) do |args|
    # This will add to the catalog, and to the node specifically:
    # - A global 'role' hash with the 'role::#{arg}' key set to true; if the variable is present, append to it
    # - Include class role::#{arg} if present

    # Prevent use outside of node definitions
    if not self.is_nodescope?
      raise Puppet::ParseError,
            "role can only be used in node scope, while you are in scope #{self}"
    end
    container = '_roles'

    args.flatten.each do |arg|
      # sanitize arg
      if arg.start_with? '::'
        arg = arg.gsub(/^::/,'')
      end
      rolename = 'role::' + arg
      rolevar = compiler.topscope.lookupvar(container)
      if rolevar
        rolevar[arg] = true
      else
        compiler.topscope.setvar(container, {arg => true})
      end

      role_class = compiler.topscope.find_hostclass(rolename)
      if role_class
        send Puppet::Parser::Functions.function(:include), [rolename]
      else
        Puppet.warning "Role class #{rolename} not found"
      end
    end
  end
end
