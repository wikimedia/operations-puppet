begin
  require 'puppet_x/bodgit/postfix/util'
rescue LoadError
  # :nocov:
  require 'pathname'
  require Pathname.new(__FILE__).dirname + '../../' + 'puppet_x/bodgit/postfix/util'
  # :nocov:
end

Puppet::Type.newtype(:postfix_main) do
  include PuppetX::Bodgit::Postfix::Util

  @doc = 'Manages Postfix settings.

The resource name can be used as a shortcut for specifying the setting
parameter.'

  ensurable

  newparam(:name) do
    desc 'The name of the setting or a unique string.'
  end

  newparam(:setting) do
    desc 'The name of the setting.'
    isnamevar
    munge do |value|
      value.to_s
    end
  end

  def self.title_patterns
    [
      [
        %r{^(\S+)$},
        [
          [:setting],
        ],
      ],
    ]
  end

  newproperty(:value) do
    desc 'Value to change the setting to.

If this value is refers to other settings and those settings are also managed
by Puppet, they will be autorequired. If the value can be fully expanded and
matches a file resource that exists in the catalogue then it will be
autorequired. Lookup tables of the form `type:/path/to/file` will use the
filename that is produced by the `postmap(1)` command. For example, a value of
`hash:/etc/aliases` will attempt to autorequire `/etc/aliases.db`. Any setting
that references a service defined in `master.cf` will attempt to autorequire
it. This includes the various `${transport}_delivery_slot_cost`, etc.
settings.'
    munge do |value|
      value.to_s
    end
  end

  newparam(:target) do
    desc 'The file in which to store the settings, defaults to
`/etc/postfix/main.cf`.

If a file resource exists in the catalogue for this value it will be
autorequired.'
  end

  def value_split(value)
    value.split(%r{[\s,]+})
  end

  autorequire(:file) do
    autos = []
    autos << self[:target] if self[:target]
    if self[:value]
      values = value_split(self[:value]).map do |x|
        expand(x)
      end

      autos += file_autorequires(values)
    end
    autos
  end

  autorequire(:postfix_main) do
    autos = []
    if self[:value]
      value_split(self[:value]).each do |v|
        value_scan(v) do |x|
          autos << x
        end
      end
    end
    autos
  end

  autorequire(:postfix_master) do
    autos = []
    case self[:setting]
    when %r{_service_name$}
      autos += [
        "#{self[:value]}/inet",
        "#{self[:value]}/unix",
        "#{self[:value]}/fifo",
        "#{self[:value]}/pass",
      ]
    when %r{
      ^
      ([^_]+)
      _
      (?:
        delivery_slot_
        (?:
          cost
          |
          discount
          |
          loan
        )
        |
        destination_
        (?:
          concurrency_
          (?:
            (?:
              failed_cohort_
            )?
            limit
            |
            (?:
              negative
              |
              positive
            )
            _feedback
          )
          |
          rate_delay
          |
          recipient_limit
        )
        |
        extra_recipient_limit
        |
        initial_destination_concurrency
        |
        minimum_delivery_slots
        |
        recipient_
        (?:
          limit
          |
          refill_
          (?:
            delay
            |
            limit
          )
        )
      )
      $
      }x
      if Regexp.last_match(1) != 'default'
        autos += [
          "#{Regexp.last_match(1)}/inet",
          "#{Regexp.last_match(1)}/unix",
          "#{Regexp.last_match(1)}/fifo",
          "#{Regexp.last_match(1)}/pass",
        ]
      end
    end
    autos
  end
end
