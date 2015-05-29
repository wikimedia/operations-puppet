# This sets two facter facts:
# canon_v4addr - The IPv4 address corresponding to the host's hostname,
#                from its own local point of view
# canon_v4addr_iface - The local interface name the above is configured on
#
# I'm inclined to say this should raise the commented-out errors if it fails,
#  but at least initially I'd like to test its reliability on the fleet first.
#

require 'socket'

Facter.add(:canon_v4addr) do
    setcode do
        canon_v4addr = nil
        ai = Socket.getaddrinfo(Socket.gethostname, nil, Socket::AF_INET, nil, nil)
        ai.each do |af, port, hn, addr|
            if addr !~ /^127\./
                canon_v4addr = addr
                break
            end
        end
        # if canon_v4addr.nil?
        #     raise "This host cannot find its own primary ipv4 address"
        # end
        canon_v4addr
    end
end

Facter.add(:canon_v4addr_iface) do
    setcode do
        v4a = Facter.value(:canon_v4addr)
        canon_v4addr_iface = nil
        current_iface = nil
        %x{/sbin/ip -4 addr show}.split("\n").each do |line|
            if match = line.match(/^[0-9]+: ([^:]+):/)
                current_iface = match.captures[0]
            elsif match = line.match(/\b#{Regexp.escape(v4a)}\b/)
                canon_v4addr_iface = current_iface
            end
        end
        # if canon_v4addr_iface.nil?
        #     raise "This host cannot find the interface for its own primary ipv4 address"
        # end
        canon_v4addr_iface
    end
end
