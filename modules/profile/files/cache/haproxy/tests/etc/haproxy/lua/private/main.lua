-- SPDX-License-Identifier: Apache-2.0

local function score_stub(txn)
  txn:set_var('txn.request_score', 42)
end

core.register_action('request_check', {'http-req'}, score_stub)
