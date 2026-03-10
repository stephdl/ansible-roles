ALTER TABLE `application_log`
  MODIFY COLUMN `logtimestamp` decimal(20,5) unsigned DEFAULT NULL;

ALTER TABLE `audittrail`
  MODIFY COLUMN `logtimestamp` decimal(20,5) unsigned DEFAULT NULL;

ALTER TABLE `crl`
  ADD COLUMN `profile` varchar(64) DEFAULT NULL
  AFTER `issuer_identifier`;
ALTER TABLE `crl`
  ADD KEY `profile` (`profile`);

ALTER TABLE `datapool`
  ADD COLUMN `access_key` varchar(255) NULL DEFAULT NULL
  AFTER `encryption_key`;

ALTER TABLE `workflow`
  ADD COLUMN `workflow_archive_at` int(10) unsigned DEFAULT NULL
  AFTER `workflow_reap_at`;
ALTER TABLE `workflow`
  ADD KEY `watchdog_archive_at` (`workflow_archive_at`, `watchdog_key`, `workflow_proc_state`);

