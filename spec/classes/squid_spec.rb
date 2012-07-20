# vim: ts=2 sw=2 noet
require 'spec_helper'

describe '::squid', :type => :class do

	context 'Squid class specs' do
		let( :facts ) do {
#			:testing_in_rspec => true,
			:realm            => 'production',
			:ipaddress        => '10.0.0.1', #pmtpa
			:operatingsystem  => 'ubuntu',
			:squid_coss_disks => [ 'sda5', 'sdb5' ],
		} end

		it {
			should contain_service('squid').with( { 'name' => 'squid' } )
		}
	end

end
