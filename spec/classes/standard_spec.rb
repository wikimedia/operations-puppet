# vim: ts=2 sw=2 noet
require 'spec_helper'

describe '::standard', :type => :class do

	context 'Standard should provide very basic functionalities' do
		let( :facts ) do {
			:realm           => 'production',
			:ipaddress       => '10.0.0.1', #pmtpa
			:operatingsystem => 'ubuntu',
		} end

		it {
			should include_class('base')
			should include_class('ganglia')
			should include_class('ntp::client')
			should include_class('exim::simple-mail-sender')
		}
	end

end
