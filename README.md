
### Using xtrabackup backup mysql data to remote backup server:
[mysql_backup script](./script/remote_backup.sh)

- mysql server
```
# remote backup server: 192.168.0.100
echo "192.168.0.100 backup" >>/etc/hosts
# install
yum install qpress pv -y
# mysql server host: 192.168.0.50 , instance: dba
30 1 * * * source /etc/profile && cd ~/script/mysql_backup && /bin/bash remote_backup.sh '/etc/my.cnf' dba >> ~/script/mysql_backup/backup.log
```
-  Bakcup info will be written into a mysql manage server
```
# create table backup_stat
CREATE TABLE `backup_stat` (
`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
`task` varchar(30) NOT NULL,
`backup_name` varchar(50) NOT NULL,
`is_incr` tinyint(3) unsigned NOT NULL DEFAULT '1',
`is_sucess` tinyint(3) unsigned NOT NULL,
`cost_time` float(5, 2) DEFAULT NULL,
`started_at` datetime NOT NULL,
`task_host` varchar(100) NOT NULL,
`storage_host` varchar(40) NOT NULL DEFAULT '192.168.0.100',
`job_name` varchar(50) NOT NULL,
`remote_backup_dir` varchar(100) NOT NULL,
`created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
`updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
PRIMARY KEY (`id`),
KEY `idx_task_st` (`task`(15), `started_at`),
KEY `idx_ctime` (`cost_time`),
KEY `idx_ct` (`created_at`)
) ENGINE = InnoDB AUTO_INCREMENT = 303 DEFAULT CHARSET = utf8mb4;
```
![backup info](back_info.jpg)
