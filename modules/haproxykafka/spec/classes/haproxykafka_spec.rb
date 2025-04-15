# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'haproxykafka' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:params) {
        {
          user: 'haproxykafka',
          config: {
            workers: 1,
            message_buffer: 1024.0,
            sdid: 'haproxykafka@0',
            hostname: "test",
            socket: {
              path: '/var/run/haproxykafka.sock',
              mode: '0622',
              user: 'haproxykafka',
              group: 'haproxykafka',
              batch_size: 1024,
              batch_deadline: '100ms',
            },
            logparser: {
              batch_size: 1024,
              batch_deadline: '100ms',
            },
            kafka: {
              topic: 'test-topic',
              dlq_topic: 'test-dlq',
              flush_timeout: 100,
              batch_size: 1024,
              batch_deadline: '100ms',
              rdkafka: {
                acks: "all",
                'client.id': "test-hostname",
                'security.protocol': "SSL",
                'ssl.ca.location': "/etc/ssl/certs/wmf-ca-certificates.crt",
                'ssl.certificate.location': "/tmp/test.file",
                'ssl.key.location': "/tmp/test.file",
                'ssl.cipher.suites': "ECDHE-ECDSA-AES256-GCM-SHA384",
                'ssl.curves.list': "P-256",
                'ssl.sigalgs.list': "ECDSA+SHA256",
                'queue.buffering.max.messages': 720_000,
                'queue.buffering.max.ms': 1000,
                'batch.num.messages': 9000,
                'compression.codec': "snappy",
                'topic.request.required.acks': 1,
              },
            },
            monitoring: {
              enable_pprof: true,
              enable_prometheus: true,
              server_bind: ":1234",
              prometheus_prefix: "haproxykafka_",
              prometheus_parsing_buckets: [1.0e-5, 1.0e-4],
              prometheus_processing_buckets: [1.0e-5, 1.0e-4],
            },
            transform_rules: {
              haproxy_format: '02/Jan/2006:15:04:05.000',
              date_format: "2006-01-02T15:04:05Z",
              date_tz: "UTC",
            },
          },
        }
      }
      context "On ensure absent" do
        let(:params) { super().merge('ensure' => 'absent') }
        it { is_expected.to compile.with_all_deps }
      end
      context "On ensure present" do
        let(:params) { super().merge('ensure' => 'present') }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('haproxykafka') }
        it { is_expected.to contain_file('/var/run/haproxykafka').with({
            'ensure' => 'directory',
            'owner' => 'haproxykafka',
            'mode' => '0755',
          })
        }
        it { is_expected.to contain_user('haproxykafka') }
        it { is_expected.to contain_service('haproxykafka') }
        it { is_expected.to contain_file('/etc/haproxykafka').with_ensure('directory') }
        it { is_expected.to contain_file('/etc/haproxykafka/config.yaml').with({
            'ensure' => 'present',
            'owner' => 'haproxykafka',
            'mode' => '0444',
          })
        }
        it { is_expected.to contain_file('/etc/haproxykafka/config.yaml').with_content(<<-EOM
---
workers: 1
message_buffer: 1024.0
sdid: haproxykafka@0
hostname: test
socket:
  path: "/var/run/haproxykafka.sock"
  mode: '0622'
  user: haproxykafka
  group: haproxykafka
  batch_size: 1024
  batch_deadline: 100ms
logparser:
  batch_size: 1024
  batch_deadline: 100ms
kafka:
  topic: test-topic
  dlq_topic: test-dlq
  flush_timeout: 100
  batch_size: 1024
  batch_deadline: 100ms
  rdkafka:
    acks: all
    client.id: test-hostname
    security.protocol: SSL
    ssl.ca.location: "/etc/ssl/certs/wmf-ca-certificates.crt"
    ssl.certificate.location: "/tmp/test.file"
    ssl.key.location: "/tmp/test.file"
    ssl.cipher.suites: ECDHE-ECDSA-AES256-GCM-SHA384
    ssl.curves.list: P-256
    ssl.sigalgs.list: ECDSA+SHA256
    queue.buffering.max.messages: 720000
    queue.buffering.max.ms: 1000
    batch.num.messages: 9000
    compression.codec: snappy
    topic.request.required.acks: 1
monitoring:
  enable_pprof: true
  enable_prometheus: true
  server_bind: ":1234"
  prometheus_prefix: haproxykafka_
  prometheus_parsing_buckets:
  - 1.0e-05
  - 0.0001
  prometheus_processing_buckets:
  - 1.0e-05
  - 0.0001
transform_rules:
  haproxy_format: 02/Jan/2006:15:04:05.000
  date_format: '2006-01-02T15:04:05Z'
  date_tz: UTC
EOM
) }
      end
    end
  end
end
