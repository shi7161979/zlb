# ZLB Openresty+Consul_template 实现动态负载均衡

- ZLB 主要通过域名来做反向代理实现负载均衡
- ZLB 利用Openresty来做负载均衡，结合Consul_Template监听注册到Consul中的KV，从而支持分布式的负载均衡
- ZLB 对https://github.com/shi7161979/lua-resty-upstream-healthcheck 进行了适当修改，是的其健康检查可以支持HTTP和TCP两种方式。
- ZLB 通过容器的方式进行启动

> 执行如下命令制作镜像 
make image

> 启动容器
docker run -it -d --net="host" -e CONSUL_8500_TCP_ADDR=127.0.0.1:8500  zlb

> 查看后端服务器健康状态
curl -v http://127.0.0.1/zlb_status  
Nginx Worker PID: 17

> 注入相应的域名  
curl -X PUT --data="" "http://127.0.0.8500/v1/kv/zlb_domain/a.com/192.168.13.21"  
curl -X PUT "http://172.17.211.87:8500/v1/kv/zlb_domain/a.com/127.0.0.1:80"  

> 查看后端健康状态
curl -v http://127.0.0.1/zlb_status 
Nginx Worker PID: 20
Upstream a.com
    Primary Peers
        127.0.0.1:80 up 
        192.168.13.21:80 DOWN
    Backup Peers
>注入相应的后端健康检查规则
- TCP层面健康检查
  curl -X PUT -d '{"type":"tcp"}' "http://127.0.0.1:8500/v1/kv/zlb_healthcheck/a.com"
- HTTP层面健康检查
 curl -X PUT -d '{"concurrency":10,"rise":2,"interval":2000,"valid_statuses":"200,404,302,301","uri":"/check","timeout":1000,"fall":3,"type":"http"}' "http://127.0.0.1:8500/v1/kv/zlb_healthcheck/a.com"
各参数含义参考 https://github.com/shi7161979/lua-resty-upstream-healthcheck
>带域名访问
curl -v http://127.0.0.1/ -H "Host: a.com"
