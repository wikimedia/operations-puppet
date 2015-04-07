# == Function: role ( string $role_name [, string $... ] )
#
# Declare the _roles variable (or add keys to it), and if the role class
# role::$role_name is in the scope, include it. This is roughly a
# shortcut for
#
# $::_roles[foo] = true
# include role::foo
#
# and has the notable advantage over that the syntax is shorter. Also,
# this function  will refuse to run anywhere but at the node scope,
# thus making any additional role added to a node explicit.
#
# If you have more than one role to declare, you MUST do that in one
# single role stanza, or you would encounter unexpected behaviour. If
# you do, an exception will be raised.
#
# This function is very useful with our "role" hiera backend if you
# have global configs that are role-based
#
# === Example
#
# node /^www\d+/ {
#     role mediawiki::appserver  # this will load the role::mediawiki::appserver class
#     include standard  #this class will use hiera lookups defined for the role.
# }
#
# node monitoring.local {
#     role icinga, ganglia::collector #GOOD
# }
#
# node monitoring2.local {
#     role icinga
#     role ganglia::collector #BAD, issues a warning
# }

module Puppet::Parser::Functions
  newfunction(:role, :arity => -1) do |args|
    # This will add to the catalog, and to the node specifically:
    # - A global 'role' hash with the 'role::#{arg}' key set to true;
    # if the variable is present, append to it
    # - Include class role::#{arg} if present

    # Prevent use outside of node definitions
    if not self.is_nodescope?
      raise Puppet::ParseError,
            "role can only be used in node scope, while you are in scope #{self}"
    end

    # Now check if the variable is already set and issue a warning
    container = '_roles'
    rolevar = compiler.topscope.lookupvar(container)
    if rolevar
      raise Puppet::ParseError,
            "Using 'role' multiple times might yield unexpected results, use 'role role1, role2' instead"
    else
      compiler.topscope.setvar(container, {})
      rolevar = compiler.topscope.lookupvar(container)
    end

    # sanitize args
    args = args.map do |x|
      if x.start_with? '::'
        x.gsub(/^::/, '')
      else
        x
      end
    end

    # Set the variables
    args.each do |arg|
      rolevar[arg] = true
    end

    args.each do |arg|
      rolename = 'role::' + arg
      role_class = compiler.topscope.find_hostclass(rolename)
      if role_class
        send Puppet::Parser::Functions.function(:include), [rolename]
      else
        raise Puppet::ParseError, "Role class #{rolename} not found"
      end
    end
  end
end
