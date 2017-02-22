require 'spec_helper'

describe 'systemd::sidekick' do
    context 'when initsystem is unknown' do
        let(:title) { 'dummyservice' }
        let(:facts) { { :initsystem => 'unknown' } }
        let(:params) { {
            :parent => nil,
            :start => nil,
            :stop => nil,
        } }
        it { should compile.and_raise_error(/systemd::service_sidekick only works with systemd/) }
    end

    context 'when initsystem is sytemd' do
        let(:facts) { {:initsystem => 'systemd' } }
        let(:title) { 'dummyservice' }
        let(:pre_condition) {
            """
            base::service_unit { 'parent-service': }
            """
        }

        describe 'when using dummy parameters' do
            let(:params) { {
                :parent => 'parent-service',
                :start => nil,
                :stop => nil,
            } }
            it { should compile }

            describe 'then the systemd service' do
                it 'should have a description that refers to parent service' do
                    should contain_file('/lib/systemd/system/parent-service-sidekick-dummyservice.service')
                        .with_content(/^Description=.*parent-service.*/)
                end
                it 'should bind to the parent service' do
                    should contain_file('/lib/systemd/system/parent-service-sidekick-dummyservice.service')
                        .with_content(/^BindsTo=parent-service.service$/)
                end
                it 'should run after the parent service' do
                    should contain_file('/lib/systemd/system/parent-service-sidekick-dummyservice.service')
                        .with_content(/^After=parent-service.service$/)
                end
            end
        end

        describe 'when $start and $stop start with /' do
            let(:params) { {
                :parent => 'parent-service',
                :start => '/usr/bin/dummy-start',
                :stop => '/usr/bin/dummy-stop',
            } }
            it 'should define a service using exactly the given commands' do
                should contain_file('/lib/systemd/system/parent-service-sidekick-dummyservice.service')
                    .with_content(%r%^ExecStart=/usr/bin/dummy-start$%)
                    .with_content(%r%^ExecStop=/usr/bin/dummy-stop$%)
            end
        end
        describe 'when $start and $stop are not starting with /' do
            let(:params) { {
                :parent => 'parent-service',
                :start => 'dummy-start',
                :stop => 'dummy-stop',
            } }
            it 'should wrap the command with /bin/bash -c' do
                should contain_file('/lib/systemd/system/parent-service-sidekick-dummyservice.service')
                    .with_content(%r%^ExecStart=/bin/bash -c "dummy-start"%)
                    .with_content(%r%^ExecStop=/bin/bash -c "dummy-stop"$%)
            end
        end
    end
end
