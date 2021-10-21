# == Function: role ( string $role_name [, string $... ] )
#
# Declare the _role variable and if the role class
# role::${::_role} is in the scope, include it. This is roughly a
# shortcut for
#
# $::_role = 'foo/bar'
# include role::foo::bar
#
# and has the notable advantage over that the syntax is shorter. Also,
# this function  will refuse to run anywhere but at the node scope,
# thus making any additional role added to a node explicit.
#
# You can only define one role per server. Trying to call this function multiple
# times will result in a compilation failure.
#
# This function is very useful with our "role" hiera backend if you
# have global configs that are role-based
#
# === Example
#
# node /^www\d+/ {
#     role(mediawiki::appserver)  # this will load the role::mediawiki::appserver class
#     include profile::base::production  #this class will use hiera lookups defined for the role.
# }
#
# node monitoring.local {
#     role(icinga) #GOOD
# }
#
# node monitoring2.local {
#     role(icinga)
#     role(prometheus) #BAD, compilation fails.
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
    # This is where we're going in the future
    # Hack: we transform 'foo::bar' in 'foo/bar' so that it's easy to lookup in hiera
    scope['_role'] = role.gsub(/::/, '/')
    rolename = 'role::' + role
    call_function('include', rolename)
  end
end
