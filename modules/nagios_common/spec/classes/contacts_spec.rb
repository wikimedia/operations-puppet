require 'spec_helper'

describe 'nagios_common::contacts' do

    it { is_expected.to compile }

    context 'with a dummy contact' do
        let(:params) { {
            :contacts => [
                {
                    'name' => 'John Dummy',
                }
            ],
        } }
        it 'should have have a contact name' do
            is_expected.to contain_file('/etc/icinga/contacts.cfg')
                .with_content(/contact_name\s+John Dummy$/)
        end
        it 'should not have an email set' do
            is_expected.to contain_file('/etc/icinga/contacts.cfg')
                .without_content(/^\s+email\s+/)
        end
        it 'should be notified 24x7' do
            is_expected.to contain_file('/etc/icinga/contacts.cfg')
                .with_content(/host_notification_period\s+24x7$/)
                .with_content(/service_notification_period\s+24x7$/)
        end
    end

    context 'with a contact having a notification period of business-hours' do
        let(:params) { {
            :contacts => [
                {
                    'name' => 'John Dummy',
                    'period' => 'business-hours',
                }
            ],
        } }
        it 'should only be notified during business hours' do
            is_expected.to contain_file('/etc/icinga/contacts.cfg')
                .with_content(/host_notification_period\s+business-hours$/)
                .with_content(/service_notification_period\s+business-hours$/)
        end
    end

    context 'with a contact having an email defined' do
        let(:params) { {
            :contacts => [
                {
                    'name' => 'John Dummy',
                    'email' => 'john.dummy@example.org',
                }
            ],
        } }

        it 'should have an email set' do
            is_expected.to contain_file('/etc/icinga/contacts.cfg')
                .with_content(/^\s+email\s+john.dummy@example.org$/)
        end
        it 'should be notified 24x7' do
            is_expected.to contain_file('/etc/icinga/contacts.cfg')
                .with_content(/host_notification_period\s+24x7$/)
                .with_content(/service_notification_period\s+24x7$/)
        end
        it 'should be notified by email' do
            is_expected.to contain_file('/etc/icinga/contacts.cfg')
                .with_content(/host_notification_commands\s+host-notify-by-email$/)
                .with_content(/service_notification_commands\s+host-notify-by-email$/)
        end
    end

    context 'with a contact having a single command' do
        let(:params) { {
            :contacts => [
                {
                    'name' => 'John Dummy',
                    'commands' => ['singlecmd'],
                }
            ],
        } }
        it "should be notified by the single command" do
            is_expected.to contain_file('/etc/icinga/contacts.cfg')
                .with_content(/host_notification_commands\s+host-notify-singlecmd$/)
                .with_content(/service_notification_commands\s+host-notify-singlecmd$/)
        end
    end

    context 'with a contact having multiple commands' do
        let(:params) { {
            :contacts => [
                {
                    'name' => 'John Dummy',
                    'commands' => ['cmdone', 'cmdtwo'],
                }
            ],
        } }
        it 'should be notified by multiple commands' do
            is_expected.to contain_file('/etc/icinga/contacts.cfg')
                .with_content(/host_notification_commands\s+host-notify-cmdone,host-notify-cmdtwo$/)
                .with_content(/service_notification_commands\s+host-notify-cmdone,host-notify-cmdtwo$/)
        end
    end

end
