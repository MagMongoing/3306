
```
cd /usr/local/src/

wget https://www.keepalived.org/software/keepalived-2.0.19.tar.gz

tar -xzf keepalived-2.0.19.tar.gz

cd keepalived-2.0.19/

yum install openssl-devel libnl-devel -y

./configure --prefix=/usr/local/keeplived

make && make install

```
