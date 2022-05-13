# SPDX-License-Identifier: Apache-2.0
type Cfssl::Ca_constraint = Struct[{
    is_ca             => Boolean,
    max_path_len      => Integer[0,9],
    max_path_len_zero => Optional[Boolean],
}]
