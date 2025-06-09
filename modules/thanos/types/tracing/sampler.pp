# SPDX-License-Identifier: Apache-2.0
# based on
# https://github.com/thanos-io/thanos/blob/236777732278c64ca01c1c09d726f0f712c87164/pkg/tracing/otlp/otlp.go#L28
type Thanos::Tracing::Sampler = Enum[
  'alwayssample',
  'neversample',
  'traceidratiobased',
  'parentbasedalwayssample',
  'parentbasedneversample',
  'parentbasedtraceidratiobased',
]
