-- Additional index T177096
-- Deployed with:
-- mysql -BN -A information_schema -e \
-- "SELECT table_schema FROM tables WHERE table_name='archive' and table_schema like '%wik%' and table_type='BASE TABLE'" \
-- | while read db; do echo "ALTER TABLE $db.archive ADD KEY user_timestamp (ar_user,ar_timestamp);"; \
-- mysql -A $db -e "ALTER TABLE $db.archive ADD KEY user_timestamp (ar_user,ar_timestamp);"; done

ALTER TABLE archive ADD KEY `user_timestamp` (`ar_user`,`ar_timestamp`);
