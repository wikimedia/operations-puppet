# Lame test for git::userconfig, making sure the expanded gitconfig.erb expands
# to a somehow valid .gitconfig file
#
# Copyright 2013 Antoine "hashar" Musso
# Copyright 2013 Wikimedia Foundation Inc.

require 'spec_helper'

describe 'git::userconfig', :type => :define do

	let(:title) { 'gitconfig' }

	context "Setting up user name and email" do
		let(:params) { {
			:homedir => '/tmp/foo',
			:settings => {
			'user' => {
				'name' => 'Antoine Musso',
				'email' => 'hashar@free.fr',
			}
		}, }
		}
		it { should contain_file('/tmp/foo/.gitconfig') \
			.with_content(/[user]\n/) \
			.with_content(/name = Antoine Musso\n/) \
			.with_content(/email = hashar@free.fr\n/)
		}
	end

end
