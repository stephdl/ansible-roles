CREATE TABLE IF NOT EXISTS `frontend_session` (
  `session_id` varchar(255) NOT NULL PRIMARY KEY,
  `data` longtext,
  `created` int(10) unsigned NOT NULL,
  `modified` int(10) unsigned NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
