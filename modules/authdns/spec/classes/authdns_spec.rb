require 'spec_helper'

describe 'authdns' do
	let(:node) { 'testhost.eqiad.wmnet' }
	let(:params) { {
		:lvs_services => {},
		:discovery_services => {},
	} }
	let(:pre_condition) { [
		'define git::clone($directory, $origin, $branch,$owner,$group) {}',
		'define monitoring::service($description,$check_command) {}',
		'define ssh::userkey($content) {}',
		'define sudo::user($privileges) {}',
		'class confd($prefix) {}',
		'package{ "git": }',
	] }
	it { should compile }
end

describe 'authdns::lint' do
    it { should compile }
end
