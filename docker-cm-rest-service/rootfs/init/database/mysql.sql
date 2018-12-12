---

CREATE TABLE IF NOT EXISTS dns (
  id         int(11) not null AUTO_INCREMENT,
  ip         varchar(16) not null default '',
  name       varchar(160) not null default '',
  fqdn       varchar(160) not null default '',
  status     enum('offline','online','delete','prepare','unknown') default 'unknown',
  creation   DATETIME DEFAULT   CURRENT_TIMESTAMP,
  changed    DATETIME ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  key(`ip`) );

CREATE TABLE IF NOT EXISTS config (
  `key`      varchar(128),
  `value`    text not null,
  dns_ip     varchar(16),
  creation   DATETIME DEFAULT   CURRENT_TIMESTAMP,
  changed    DATETIME ON UPDATE CURRENT_TIMESTAMP,
  KEY(`key`),
  FOREIGN KEY (`dns_ip`)
  REFERENCES dns(`ip`)
  ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS discovery (
  service    varchar(128) not null,
  port       int(4) not null,
  data       text not null,
  dns_ip     varchar(16),
  creation   DATETIME DEFAULT   CURRENT_TIMESTAMP,
  changed    DATETIME ON UPDATE CURRENT_TIMESTAMP,
  KEY(`service`),
  FOREIGN KEY (`dns_ip`)
  REFERENCES dns(`ip`)
  ON DELETE CASCADE
);



