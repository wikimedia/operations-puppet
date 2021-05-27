# frozen_string_literal: true

Puppet::Type.newtype(:concat_fragment) do
  @doc = <<-DOC
    @summary
      Manages the fragment.

    @example
      # The example is based on exported resources.

      concat_fragment { \"uniqe_name_${::fqdn}\":
        tag => 'unique_name',
        order => 10, # Optional. Default to 10
        content => 'some content' # OR
        # content => template('template.erb')
        source  => 'puppet:///path/to/file'
      }
  DOC

  newparam(:name, namevar: true) do
    desc 'Name of resource.'
  end

  newparam(:target) do
    desc <<-DOC
      Required. Specifies the destination file of the fragment. Valid options: a string containing the path or title of the parent
      concat_file resource.
    DOC

    validate do |value|
      raise ArgumentError, _('Target must be a String') unless value.is_a?(String)
    end
  end

  newparam(:content) do
    desc <<-DOC
      Supplies the content of the fragment. Note: You must supply either a content parameter or a source parameter. Valid options: a string
    DOC

    validate do |value|
      raise ArgumentError, _('Content must be a String') unless value.is_a?(String)
    end
  end

  newparam(:source) do
    desc <<-DOC
      Specifies a file to read into the content of the fragment. Note: You must supply either a content parameter or a source parameter.
      Valid options: a string or an array, containing one or more Puppet URLs.
    DOC

    validate do |value|
      raise ArgumentError, _('Content must be a String or Array') unless [String, Array].include?(value.class)
    end
  end

  newparam(:order) do
    desc <<-DOC
      Reorders your fragments within the destination file. Fragments that share the same order number are ordered by name. The string
      option is recommended.
    DOC

    defaultto '10'
    validate do |val|
      raise Puppet::ParseError, _('$order is not a string or integer.') unless val.is_a?(String) || val.is_a?(Integer)
      raise Puppet::ParseError, _('Order cannot contain \'/\', \':\', or \'\\n\'.') if %r{[:\n\/]}.match?(val.to_s)
    end
  end

  newparam(:tag) do
    desc 'Specifies a unique tag to be used by concat_file to reference and collect content.'
  end

  autorequire(:file) do
    found = catalog.resources.select do |resource|
      next unless resource.is_a?(Puppet::Type.type(:concat_file))

      resource[:path] == self[:target] || resource.title == self[:target] ||
        (resource[:tag] && resource[:tag] == self[:tag])
    end

    if found.empty?
      tag_message = (self[:tag]) ? "or tag '#{self[:tag]} " : ''
      warning "Target Concat_file with path or title '#{self[:target]}' #{tag_message}not found in the catalog"
    end
  end

  validate do
    # Check if target is set
    raise Puppet::ParseError, _("No 'target' or 'tag' set") unless self[:target] || self[:tag]

    # Check if either source or content is set. raise error if none is set
    raise Puppet::ParseError, _("Set either 'source' or 'content'") if self[:source].nil? && self[:content].nil?

    # Check if both are set, if so rais error
    raise Puppet::ParseError, _("Can't use 'source' and 'content' at the same time") if !self[:source].nil? && !self[:content].nil?
  end
end
