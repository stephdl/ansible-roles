/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `fd_comment` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `poll_id` varchar(64) NOT NULL,
  `name` varchar(64) DEFAULT NULL,
  `comment` text NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `poll_id` (`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `fd_framadate_migration` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  `execute_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `fd_poll` (
  `id` varchar(64) NOT NULL,
  `admin_id` char(24) NOT NULL,
  `title` text NOT NULL,
  `description` text,
  `admin_name` varchar(64) DEFAULT NULL,
  `admin_mail` varchar(128) DEFAULT NULL,
  `creation_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `end_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `format` varchar(1) DEFAULT NULL,
  `editable` tinyint(1) DEFAULT '0',
  `receiveNewVotes` tinyint(1) DEFAULT '0',
  `receiveNewComments` tinyint(1) DEFAULT '0',
  `active` tinyint(1) DEFAULT '1',
  `hidden` tinyint(1) NOT NULL DEFAULT '0',
  `password_hash` varchar(255) DEFAULT NULL,
  `results_publicly_visible` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `fd_slot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `poll_id` varchar(64) NOT NULL,
  `title` text,
  `moments` text,
  PRIMARY KEY (`id`),
  KEY `poll_id` (`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `fd_vote` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uniqId` char(16) NOT NULL,
  `poll_id` varchar(64) NOT NULL,
  `name` varchar(64) NOT NULL,
  `choices` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `poll_id` (`poll_id`),
  KEY `uniqId` (`uniqId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
