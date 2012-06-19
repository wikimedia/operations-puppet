Facter.add("package_updates") do
	confine :operatingsystem => %w{Debian Ubuntu}
	setcode do
		%x{/usr/local/bin/apt2xml 2>/dev/null}.chomp
	end
end
