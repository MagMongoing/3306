> 最近工作中使用归档遇到一些问题:
>1. 中文乱码问题
>2. 大表归档的备份问题

### 1. 中文乱码问题
`--charset=utf8mb4`, 会提示`Cannot find encoding "utf8mb4" at /usr/bin/pt-archiver line 6666.`。

`--charset=utf8`, 而库上表的字符集为utf8mb4, 会提示字符集不一致， 可以设置`--nocheck-charset`跳过字符集检查，在没有以下2种设置的情况下，出现了中文乱码情况。

乱码问题，怀疑，从导出的临时数据文件解码导入数据时，解码使用的字符集错误导致乱码存入目标库， 由于存入前数据已乱码，存入后，无法在库上修复。

- 数据库配置文件
在配置文件`/etc/my.cnf`添加：
```
[client]
default-character-set=utf8mb4
```
`--charset` 可以不指定，使用`--no-check-charset` 时，中文也能正常归档

- pt-archiver 设置参数避免乱码, 归档脚本参考script目录
源库和目标库`DSN` 指定字符集`A=utf8mb4`

`--charset=utf8`
```
LOAD DATA LOCAL INFILE ? INTO TABLE `ebike`.`op_move_bike_archive`CHARACTER SET utf8(`id`,`bike_sn`,`longitude`,`latitude`,`bike_start_loc`,`bike_end_loc`,`user_start_loc`,`user_end_loc`,`start_picture`,`end_picture`,`op_region_id`,`city_id`,`status`,`is_valid`,`start_time`,`end_time`,`ex_status`,`move_type`,`protect_period`,`start_parking_area`,`end_parking_area`,`not_move_hour`,`orders`,`battery_before`,`op_status`,`station_id`,`old_station_id`,`station_name`,`user_loc_type`,`user_distance`,`bike_loc_type`,`bike_distance`,`creator_id`,`creator_name`,`not_move_bike`,`in_service_area`,`create_time`,`update_time`,`end_op_region_id`)
```

### 2. utf8mb4字符集下，emoj表情归档报错 
>Cannot find encoding "utf8mb4" at /usr/bin/pt-archiver line 6666.



### 3. 大表归档的备份问题
考虑到数据归档出问题后，数据恢复的问题， 使用带条件的mysqldump备份，按归档条件分割，备份出多个小备份文件，方便恢复。固定脚本，备份一块，归档一块。




### 需要解决的问题
load data local 字符集有关的问题

perl报错的问题
