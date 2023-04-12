require 'puppet/parameter/boolean'

module Puppet
  Type.newtype(:ssh_authorized_key) do
    @doc = "@summary Manages SSH authorized keys. Currently only type 2 keys are supported.

      In their native habitat, SSH keys usually appear as a single long line, in
      the format `<TYPE> <KEY> <NAME/COMMENT>`. This resource type requires you
      to split that line into several attributes.

      @example Thus, a key that appears in your `~/.ssh/id_rsa.pub` file like this...

          ssh-rsa AAAAB3Nza[...]qXfdaQ== nick@magpie.example.com

      @example ...would translate to the following resource:

          ssh_authorized_key { 'nick@magpie.example.com':
            ensure => present,
            user   => 'nick',
            type   => 'ssh-rsa',
            key    => 'AAAAB3Nza[...]qXfdaQ==',
          }

      To ensure that only the currently approved keys are present, you can purge
      unmanaged SSH keys on a per-user basis.

      @example Do this with the `user` resource type's `purge_ssh_keys` attribute:

          user { 'nick':
            ensure         => present,
            purge_ssh_keys => true,
          }

      This will remove any keys in `~/.ssh/authorized_keys` that aren't being
      managed with `ssh_authorized_key` resources. See the documentation of the
      `user` type for more details.

      **Autorequires:** If Puppet is managing the user account in which this
      SSH key should be installed, the `ssh_authorized_key` resource will autorequire
      that user."

    ensurable

    newparam(:name) do
      desc "The SSH key comment. This can be anything, and doesn't need to match
        the original comment from the `.pub` file.

        Due to internal limitations, this must be unique across all user accounts;
        if you want to specify one key for multiple users, you must use a different
        comment for each instance."

      isnamevar
    end

    newparam(:drop_privileges, boolean: true, parent: Puppet::Parameter::Boolean) do
      desc "Whether to drop privileges when writing the key file. This is
        useful for creating files in paths not writable by the target user. Note
        the possible security implications of managing file ownership and
        permissions as a privileged user."

      defaultto true
    end

    newproperty(:type) do
      desc 'The encryption type used.'

      newvalues :'ssh-dss', :'ssh-rsa', :'ecdsa-sha2-nistp256', :'ecdsa-sha2-nistp384', :'ecdsa-sha2-nistp521', :'ssh-ed25519',
                :'sk-ecdsa-sha2-nistp256@openssh.com', :'sk-ssh-ed25519@openssh.com', :'ssh-rsa-cert-v01@openssh.com',
                :'ssh-ed25519-cert-v01@openssh.com', :'ssh-dss-cert-v01@openssh.com', :'ecdsa-sha2-nistp256-cert-v01@openssh.com',
                :'ecdsa-sha2-nistp384-cert-v01@openssh.com', :'ecdsa-sha2-nistp521-cert-v01@openssh.com'

      aliasvalue(:dsa, :'ssh-dss')
      aliasvalue(:ed25519, :'ssh-ed25519')
      aliasvalue(:rsa, :'ssh-rsa')
      aliasvalue(:'ecdsa-sk', :'sk-ecdsa-sha2-nistp256@openssh.com')
      aliasvalue(:'ed25519-sk', :'sk-ssh-ed25519@openssh.com')
    end

    newproperty(:key) do
      desc "The public key itself; generally a long string of hex characters. The `key`
        attribute may not contain whitespace.

        Make sure to omit the following in this attribute (and specify them in
        other attributes):

        * Key headers, such as 'ssh-rsa' --- put these in the `type` attribute.
        * Key identifiers / comments, such as 'joe@joescomputer.local' --- put these in
          the `name` attribute/resource title."

      validate do |value|
        raise Puppet::Error, _('Key must not contain whitespace: %{value}') % { value: value } if %r{\s}.match?(value)
      end
    end

    newproperty(:user) do
      desc "The user account in which the SSH key should be installed. The resource
        will autorequire this user if it is being managed as a `user` resource."
    end

    newproperty(:target) do
      desc "The absolute filename in which to store the SSH key. This
        property is optional and should be used only in cases where keys
        are stored in a non-standard location, for instance when not in
        `~user/.ssh/authorized_keys`. The parent directory must be present
        if the target is in a privileged path."

      defaultto :absent

      def should
        return super if defined?(@should) && @should[0] != :absent

        return nil unless resource[:user]

        begin
          File.expand_path("~#{resource[:user]}/.ssh/authorized_keys")
        rescue
          Puppet.debug 'The required user is not yet present on the system'
          nil
        end
      end

      def insync?(is)
        is == should
      end
    end

    newproperty(:options, array_matching: :all) do
      desc "Key options; see sshd(8) for possible values. Multiple values
        should be specified as an array. For example, you could use the
        following to install a SSH CA that allows someone with the
        'superuser' principal to log in as root

             ssh_authorized_key { 'Company SSH CA':
               ensure  => present,
               user    => 'root',
               type    => 'ssh-ed25519',
               key     => 'AAAAC3NzaC[...]CeA5kG',
               options => [ 'cert-authority', 'principals=\"superuser\"' ],
             }"

      defaultto { :absent }

      validate do |value|
        unless value == :absent || value =~ %r{^[-a-z0-9A-Z_]+(?:=\".*?\")?$}
          raise(
            Puppet::Error,
            _("Option %{value} is not valid. A single option must either be of the form 'option' or 'option=\"value\"'. Multiple options must be provided as an array") % { value: value },
          )
        end
      end
    end

    autorequire(:user) do
      should(:user) if should(:user)
    end

    validate do
      # Go ahead if target attribute is defined
      return if @parameters[:target].shouldorig[0] != :absent

      # Go ahead if user attribute is defined
      return if @parameters.include?(:user)

      # If neither target nor user is defined, this is an error
      raise Puppet::Error, _("Attribute 'user' or 'target' is mandatory")
    end

    # regular expression suitable for use by a ParsedFile based provider
    REGEX = %r{^(?:(.+)\s+)?(ssh-dss|ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|
            ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ecdsa-sk|ed25519-sk|
            sk-ecdsa-sha2-nistp256@openssh.com|sk-ssh-ed25519@openssh.com|
            ssh-rsa-cert-v01@openssh.com|ssh-ed25519-cert-v01@openssh.com|
            ssh-dss-cert-v01@openssh.com|ecdsa-sha2-nistp256-cert-v01@openssh.com|
            ecdsa-sha2-nistp384-cert-v01@openssh.com|ecdsa-sha2-nistp521-cert-v01@openssh.com)\s+([^ ]+)\s*(.*)$}x.freeze
    def self.keyline_regex
      REGEX
    end
  end
end
