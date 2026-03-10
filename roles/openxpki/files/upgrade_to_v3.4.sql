ALTER TABLE `certificate`
  ADD COLUMN `revocation_id` INT NULL DEFAULT NULL
  AFTER `hold_instruction_code`;

ALTER TABLE `crl`
  ADD COLUMN `max_revocation_id` INT NULL DEFAULT NULL
  AFTER `items`;

ALTER TABLE `certificate`
  ADD UNIQUE `revocation_id` (`revocation_id`);

ALTER TABLE `crl`
  ADD KEY `revocation_id` (`max_revocation_id`);
