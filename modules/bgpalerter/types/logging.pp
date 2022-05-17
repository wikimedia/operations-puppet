# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Logging = Struct[{
  directory          => String[1],
  logRotatePattern   => String[1],
  maxRetainedFiles   => Integer[1],
  maxFileSizeMB      => Integer[1],
  compressOnRotation => Boolean,
  useUTC             => Boolean,
}]
