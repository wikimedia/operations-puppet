Facter.add(:uniqueid) do
  setcode 'hostid'
  confine :kernel => %w{SunOS Linux AIX GNU/kFreeBSD}
  confine :facterversion do |version|
    # this fact was removed from facter in version 3
    version.split('.')[0].to_i > 2
  end
end
