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
#     include ::profile::standard  #this class will use hiera lookups defined for the role.
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
Puppet::Functions.create_function(:role) do
  dispatch :main do
    param 'String', :main_role
  end
  def main(main_role)
    scope = closure_scope
    # Check if the function has already been called
    if scope.include? '_role'
      raise Puppet::ParseError, "role() can only be called once per node"
    end
    role = main_role.gsub(/^::/, '')
    # Backwards compat
    scope['_roles'] = { role => true }
    # This is where we're going in the future
    # Hack: we transform 'foo::bar' in 'foo/bar' so that it's easy to lookup in hiera
    scope['_role'] = role.gsub(/::/, '/')
    rolename = 'role::' + role
    call_function('include', rolename)
  end
end
