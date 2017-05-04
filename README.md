# changenet
### 控制本地网络关系和跳转到指定的位置,  用于系统测试过程中后台的即时接口打桩,  而且不需要修改原始代码和使用代理

参数格式: 

1) ./changenet.sh  原目的IP 原目的端口 新目的IP:端口  (不能使用域名)

 ./changenet.sh IP1 800 IP2:80

将本地对 IP1 800 的访问跳转到 IP2:80

2) ./changenet.sh  原目的IP 原目的端口

 ./changenet.sh IP1 800

将 对 IP1 800 的访问跳转到本地 returnhtml 的文件静态返回

需要启用 iptables,  如出现任何网络异常, systemctl restart iptables   即可放弃任何修改进行重置 

使用 iptables -L 查看 普通规则,  使用 iptables -D OUTPUT n 手动删除某个链中的规则 

使用 iptables -t nat -L 查看 普通规则,  使用 iptables -t nat -D OUTPUT n 手动删除某个链中的规则 
