ALTER TABLE `certificate`
  DROP KEY `pki_realm_2`,
  ADD KEY `pki_realm_req_key` (`pki_realm`,`req_key`),
  ADD KEY `req_key` (`req_key`);

ALTER TABLE `csr_attributes`
  ADD KEY `pki_realm_req_key` (`pki_realm`,`req_key`);


