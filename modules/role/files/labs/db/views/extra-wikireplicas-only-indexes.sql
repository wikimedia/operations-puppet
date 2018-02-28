-- Additional index T177096
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='archive' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do echo "ALTER TABLE $db.archive ADD KEY user_timestamp (ar_user,ar_timestamp);"; \
-- mysql -A $db -e "ALTER TABLE $db.archive ADD KEY user_timestamp (ar_user,ar_timestamp);"; done

ALTER TABLE archive ADD KEY `user_timestamp` (`ar_user`,`ar_timestamp`);

-- Additional index T140609
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='page_props' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.page_props ADD KEY pp_value_prefix (pp_value(767));"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE page_props ADD KEY `pp_value_prefix` (`pp_value`(767));

-- Additional index T181650
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='protected_titles' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.protected_titles ADD KEY pt_reason_id (pt_reason_id);"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE protected_titles ADD KEY pt_reason_id (pt_reason_id);

-- Additional index T181650
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='oldimage' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.oldimage ADD KEY oi_description_deleted (oi_description_id, oi_deleted);"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE oldimage ADD KEY oi_description_deleted (oi_description_id, oi_deleted);

-- Additional index T181650
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='ipblocks' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.ipblocks ADD KEY ipb_reason_deleted (ipb_reason_id, ipb_deleted);"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE ipblocks ADD KEY ipb_reason_deleted (ipb_reason_id, ipb_deleted);

-- Additional index T181650
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='logging' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.logging ADD KEY log_comment_type (log_deleted, log_type, log_comment_id);"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE logging ADD KEY log_comment_type (log_type, log_comment_id, log_deleted);

-- Additional index T181650
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='recentchanges' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.recentchanges ADD KEY rc_comment_deleted (rc_comment_id, rc_deleted);"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE recentchanges ADD KEY rc_comment_deleted (rc_comment_id, rc_deleted);

-- Additional index T181650
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='filearchive' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.filearchive ADD KEY fa_description_deleted (fa_description_id, fa_deleted);"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE filearchive ADD KEY fa_description_deleted (fa_description_id, fa_deleted);

-- Additional index T181650
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='filearchive' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.filearchive ADD KEY fa_reason (fa_deleted_reason_id);"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE filearchive ADD KEY fa_reason (fa_deleted_reason_id);

-- Additional index T181650
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='revision_comment_temp' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.revision_comment_temp ADD KEY revcomment_comment_id (revcomment_comment_id);"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE revision_comment_temp ADD KEY revcomment_comment_id (revcomment_comment_id);

-- Additional index T181650
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='image_comment_temp' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do \
-- s="ALTER TABLE $db.image_comment_temp ADD KEY imgcomment_description_id (imgcomment_description_id, imgcomment_name);"; \
-- echo "$s"; \
-- mysql -A $db -e "$s"; done

ALTER TABLE image_comment_temp ADD KEY imgcomment_description_id (imgcomment_description_id, imgcomment_name);
