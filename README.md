# ZLB Openresty+Consul_template 实现动态负载均衡

- ZLB 主要通过域名来做反向代理实现负载均衡
- ZLB 利用Openresty来做负载均衡，结合Consul_Template监听注册到Consul中的KV，从而支持分布式的负载均衡
- ZLB 对https://github.com/shi7161979/lua-resty-upstream-healthcheck 进行了适当修改，是的其健康检查可以支持HTTP和TCP两种方式。
- ZLB 通过容器的方式进行启动
- ZLB 支持通过Cookie选项来进行后端upstream的跳转。该功能可用于灰度发布，AB测试等场景
- ZLB 支持设置Cookie过滤规则，在ZLB这一层拦截掉相应的Cookie
- ZLB 支持按path进行路由满足https://github.com/uniseraph/apiserver/issues/127
测试流程说明
```
#制作镜像
make image
#启动容器
make run

#consul中注入测试用例
curl -X PUT --data '{"Healthcheck":{"Type":"tcp"},"KeepAlive":1024,"Sticky":false}' "http://127.0.0.1:8500/v1/kv/zlb/www.test1.com/cfg/path_L3RyYWRl"
curl -X PUT --data '{"Healthcheck":{"Type":"tcp"},"KeepAlive":10,"Sticky":false}' "http://127.0.0.1:8500/v1/kv/zlb/www.test1.com/cfg/path_Lw=="
curl -X PUT --data '{"Healthcheck":{"Type":"tcp"},"KeepAlive":10,"Sticky":false}' "http://127.0.0.1:8500/v1/kv/zlb/www.test2.com/cfg/path_Lw=="
curl -X PUT --data "" "http://127.0.0.1:8500/v1/kv/zlb/www.test2.com/server/path_Lw==/127.0.0.1:81"
curl -X PUT --data "" "http://127.0.0.1:8500/v1/kv/zlb/tag1.www.test2.com/server/path_Lw==/127.0.0.1:85"
curl -X PUT --data "" "http://127.0.0.1:8500/v1/kv/zlb/tag2.www.test2.com/server/path_Lw==/127.0.0.1:86"
curl -X PUT --data "" "http://127.0.0.1:8500/v1/kv/zlb/www.test1.com/server/path_Lw==/127.0.0.1:82"
curl -X PUT --data "" "http://127.0.0.1:8500/v1/kv/zlb/www.test1.com/server/path_L3VzZXI=/127.0.0.1:83"
curl -X PUT --data "" "http://127.0.0.1:8500/v1/kv/zlb/www.test1.com/server/path_L3RyYWRl/127.0.0.1:84"
curl -X PUT --data "0" "http://127.0.0.1:8500/v1/kv/zlb/www.test2.com/ckfilter/userid/u1"
curl -X PUT --data "1" "http://127.0.0.1:8500/v1/kv/zlb/www.test2.com/ckfilter/userid/u2"
curl -X PUT --data "1" "http://127.0.0.1:8500/v1/kv/zlb/www.test2.com/ckfilter/X_GRAY_TAG/tag1"
curl -X PUT --data "0" "http://127.0.0.1:8500/v1/kv/zlb/www.test2.com/ckfilter/X_GRAY_TAG/tag2"


JSON 格式如下

Healthcheck: { //对应的健康检查项
  "Type":"检查类型（http|tcp）",
  "Uri":"检查类型为http时，检查的uri路径。",
  "Valid_statuses":"检查类型为http时，标记为有效的http返回状态码。多个状态码用,号隔开",
  "Interval":"健康检查的间隔时间，单位毫秒，默认为2000",
  "Timeout":"健康检查的网络超时时间，单位毫秒，默认为1000",
  "Fall":"检查时连续失败多少次计为该后端节点不可用，默认为3",
  "Ris":"对于不可用节点检查成功后连续多少次将该节点恢复为健康状态，默认为2",
  "Concurrency":"健康检查时的并发线程数"
}

KeepAlive: //后端保持长连接的个数
Sticky: //保持session粘滞（功能暂未实现)

#查看后端节点健康状况
curl http://127.0.0.1/zlb_status
Nginx Worker PID: 20
Upstream a.com
    Primary Peers
        192.168.13.21:8080 up 
     Backup Peers
Upstream b.com
    Primary Peers
        127.0.0.1:8080 up 
     Backup Peers     

#查看Cookie过滤规则
curl http://127.0.0.1/zlb_cookiefilter
{"a.com":{"X_GRAY_TAG":{"tag1":"1","tag2":"0"},"userid":{"u1":"0","u2":"1"}}}

#带Cookie验证Cookie过滤功能
curl http://127.0.0.1/ -H "Host: www.test2.com" -b "X_GRAY_TAG=tag; userid=u1; a=c"
``` 

