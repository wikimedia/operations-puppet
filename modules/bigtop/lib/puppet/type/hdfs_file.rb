# SPDX-License-Identifier: Apache-2.0
Puppet::Type.newtype(:hdfs_file) do
  @doc = "@summary Manage a file on HDFS, supporting content/source, mode, owner, and group.

      Use this type when individual files need to be managed on an HDFS file system. The file
      contents can be managed in a similar way to the regular file resource by using either the
      source or contents parameters.

      The provider for this resource type depends on using the hdfs-rsync utility and it needs
      to be executed as the hdfs user, with a matching kerberos keytab present. Therefore only
      certain hosts are capable of realising these resources.

      When ensuring that a resource is absent, the provider call the hdfs cli.

      The HDFS path should be expressed as a normal posix path, so without an hdfs:// prefix.

      The resource will use the fs.defaultFS value from /etc/hadoop/conf/core-site.xml on the host,
      so we cannot yet specify a non-default HDFS file system.

      Unless ensure is absent, the mode must be supplied and be an octal value of either 3 or 4 digits.

      Similarly, unless ensure is absent, the owner and group parameters must be supplied."

  ensurable

  newparam(:path) do
    desc "The path to the file on HDFS."
    validate do |value|
      unless value =~ %r{\A/([a-zA-Z0-9]+/)*[a-zA-Z0-9]+\z}
        raise ArgumentError, "Invalid path. This must start with a forward slash, use alphanumeric directories and not end with a trailing slash."
      end
    end
    isnamevar
  end

  newproperty(:content) do
    desc "The desired inline content of the file."

    def insync?(is)
      is == @resource[:content]
    end
  end

  newproperty(:source) do
    desc "The source file from which to copy content."

    validate do |value|
      unless Puppet::FileSystem.exist?(value)
        raise ArgumentError, "Source file #{value} does not exist."
      end
      if Puppet::FileSystem.directory?(value)
        raise ArgumentError, "Source #{value} is a directory, not a regular file."
      end
    end
  end

  newproperty(:mode) do
    desc "The desired file mode (permissions)."
    validate do |value|
      unless value =~ /\A[0-7]{3,4}\z/
        raise ArgumentError, "Invalid mode format. Should be 3 or 4 digits."
      end
    end
  end

  newproperty(:owner) do
    desc "The desired owner of the file."
    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Owner must be a string."
      end
    end
  end

  newproperty(:group) do
    desc "The desired group of the file."
    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Group must be a string."
      end
    end
  end

  validate do
    if self[:content] && self[:source]
      raise ArgumentError, "You must specify either content or source, not both."
    end

    if !self[:content] && !self[:source]
      raise ArgumentError, "You must specify either content or source."
    end
  end
end
