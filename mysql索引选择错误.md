
> percona server 5.7.23
>
> 添加单独列索引，导致执行计划选择错误，慢查后，innodb_thread_concurrency打满，2分钟内所有的查询慢查
> 
> 表数据300万，查询原执行计划使用索引idx_user_id， 添加create_time索引后，使用idx_ct



执行计划
```
>explain select ....  from user_coupon_5 use index(idx_ct) WHERE user_id in   (1342969 )  and product_type in (5)  order by create_time desc;
+----+-------------+---------------+------------+------+---------------+------+---------+------+---------+----------+-----------------------------+
| id | select_type | table         | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra                       |
+----+-------------+---------------+------------+------+---------------+------+---------+------+---------+----------+-----------------------------+
|  1 | SIMPLE      | user_coupon_5 | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 2091883 |     0.00 | Using where; Using filesort |
+----+-------------+---------------+------------+------+---------------+------+---------+------+---------+----------+-----------------------------+
>explain select ...  from user_coupon_5 use index(idx_ct) WHERE user_id in   (1342969 )  and product_type in (5)  order by create_time desc limit 0,1;
+----+-------------+---------------+------------+-------+---------------+--------+---------+------+------+----------+-------------+
| id | select_type | table         | partitions | type  | possible_keys | key    | key_len | ref  | rows | filtered | Extra       |
+----+-------------+---------------+------------+-------+---------------+--------+---------+------+------+----------+-------------+
|  1 | SIMPLE      | user_coupon_5 | NULL       | index | NULL          | idx_ct | 5       | NULL |    1 |     5.00 | Using where |
+----+-------------+---------------+------------+-------+---------------+--------+---------+------+------+----------+-------------+

>explain select ... from user_coupon_5 WHERE user_id in   (1342969 )  and product_type in (5)  order by create_time desc limit 0,1;
+----+-------------+---------------+------------+-------+---------------+--------+---------+------+------+----------+-------------+
| id | select_type | table         | partitions | type  | possible_keys | key    | key_len | ref  | rows | filtered | Extra       |
+----+-------------+---------------+------------+-------+---------------+--------+---------+------+------+----------+-------------+
|  1 | SIMPLE      | user_coupon_5 | NULL       | index | idx_user_id   | idx_ct | 5       | NULL |  834 |     0.01 | Using where |
+----+-------------+---------------+------------+-------+---------------+--------+---------+------+------+----------+-------------+

>explain select ...  from user_coupon_5 WHERE user_id in   (1342969 )  and product_type in (5)  order by create_time desc;
+----+-------------+---------------+------------+------+---------------+-------------+---------+-------+------+----------+----------------------------------------------------+
| id | select_type | table         | partitions | type | possible_keys | key         | key_len | ref   | rows | filtered | Extra                                              |
+----+-------------+---------------+------------+------+---------------+-------------+---------+-------+------+----------+----------------------------------------------------+
|  1 | SIMPLE      | user_coupon_5 | NULL       | ref  | idx_user_id   | idx_user_id | 8       | const | 2507 |    10.00 | Using index condition; Using where; Using filesort |
+----+-------------+---------------+------------+------+---------------+-------------+---------+-------+------+----------+----------------------------------------------------+



>explain select * from  ( select ...  from user_coupon_5  WHERE user_id in   (1342969 )  and product_type in (5)  order by create_time desc limit 0,1000) alias limit 1;
+----+-------------+---------------+------------+------+---------------+-------------+---------+-------+------+----------+----------------------------------------------------+
| id | select_type | table         | partitions | type | possible_keys | key         | key_len | ref   | rows | filtered | Extra                                              |
+----+-------------+---------------+------------+------+---------------+-------------+---------+-------+------+----------+----------------------------------------------------+
|  1 | PRIMARY     | <derived2>    | NULL       | ALL  | NULL          | NULL        | NULL    | NULL  |  250 |   100.00 | NULL                                               |
|  2 | DERIVED     | user_coupon_5 | NULL       | ref  | idx_user_id   | idx_user_id | 8       | const | 2507 |    10.00 | Using index condition; Using where; Using filesort |
+----+-------------+---------------+------------+------+---------------+-------------+---------+-------+------+----------+----------------------------------------------------+
>explain select ...  from user_coupon_5  WHERE user_id in   (1342969 )  and product_type in (5)  order by create_time desc limit 0,1000;
+----+-------------+---------------+------------+------+---------------+-------------+---------+-------+------+----------+----------------------------------------------------+
| id | select_type | table         | partitions | type | possible_keys | key         | key_len | ref   | rows | filtered | Extra                                              |
+----+-------------+---------------+------------+------+---------------+-------------+---------+-------+------+----------+----------------------------------------------------+
|  1 | SIMPLE      | user_coupon_5 | NULL       | ref  | idx_user_id   | idx_user_id | 8       | const | 2507 |    10.00 | Using index condition; Using where; Using filesort |
+----+-------------+---------------+------------+------+---------------+-------------+---------+-------+------+----------+----------------------------------------------------+
```





## 参考
[MySQL实战45讲 MySQL为什么会选择索引](https://time.geekbang.org/column/article/71173)

[MySQL · 捉虫动态 · order by limit 造成优化器选择索引错误](http://mysql.taobao.org/monthly/2015/11/10/)
