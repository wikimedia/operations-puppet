
Puppet::Type.newtype(:gridengine_node) do
  @doc = "Manage the various types of gridengine nodes.
    This should not be thought of as the same as gridengine servers.
    We are managing them for the system's understanding of itself."

  ensurable

  newparam(:fqdn) do
    desc "The FQDN of the server"

    isnamevar
  end

  newproperty(:type, :array_matching => :all) do
    desc "The type of gridengine node the resource represents."

    newvalues(:exec, :submit, :admin)
  end
end
