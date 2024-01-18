## 安装前的准备 
```
yum -y install epel-release 
yum -y install libpcap-devel openssl-devel python3 python3-devel python3-semantic_version
yum -y install cmake-filesystem libmaxminddb-devel python3-GitPython

yum -y install librdkafka-devel 

/opt/zeek/bin/zkg install zeek-kafka
```

# https://docs.zeek.org/en/current/log-formats.html#zeek-json-format-logs
```
/opt/zeek/bin/zeek /opt/zeek/share/zeek/site/local.zeek -C -r ../2017-06-21-Hancitor-malspam-traffic.pcap  LogAscii::use_json=T
```

## 注意新增 


```

https://github.com/cisagov/Malcolm/tree/main
```

- bzar 错误
- misc/scan 已经被替代
- 
