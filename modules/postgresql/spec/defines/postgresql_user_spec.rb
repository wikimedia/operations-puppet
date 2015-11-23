require 'spec_helper'

describe 'postgresql::user', :type => :define do
    let(:title) { 'something@host.example.com' }
    let(:params) do {
        :user     => 'something',
        :password => 'soemthing',
        :ensure   => 'present',
        }
    end
    context 'with ensure present' do
        it { should contain_exec('create_user-something@host.example.com') }
        it { should contain_exec('pass_set-something@host.example.com') }
        it { should contain_augeas('hba_create-something@host.example.com') }
    end
end

describe 'postgresql::user', :type => :define do
    let(:title) { 'something@host.example.com' }
    let(:params) do {
        :user     => 'something',
        :password => 'soemthing',
        :ensure   => 'absent',
        }
    end

    context 'with ensure absent' do
    it { should contain_exec('drop_user-something@host.example.com') }
    it { should contain_augeas('hba_drop-something@host.example.com') }
    end
end
