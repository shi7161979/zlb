# ZLB Openresty+Consul_template 实现动态负载均衡

- ZLB 主要通过域名来做反向代理实现负载均衡
- ZLB 利用Openresty来做负载均衡，结合Consul_Template监听注册到Consul中的KV，从而支持分布式的负载均衡
- ZLB 对https://github.com/shi7161979/lua-resty-upstream-healthcheck 进行了适当修改，是的其健康检查可以支持HTTP和TCP两种方式。
- ZLB 通过容器的方式进行启动
- ZLB 支持通过Cookie选项来进行后端upstream的跳转。该功能可用于灰度发布，AB测试等场景
- ZLB 支持设置Cookie过滤规则，在ZLB这一层拦截掉相应的Cookie

测试流程说明
```
#制作镜像
make image
#启动容器
make run

#consul中注入需要proxy的域名,consul 地址为127.0.0.1:8500,以下类同
curl -X PUT --data "" "http://127.0.0.1:8500/v1/kv/zlb_domain/a.com/192.168.13.21:8080"
curl -X PUT --data "" "http://127.0.0.1:8500/v1/kv/zlb_domain/b.com/127.0.0.1:8080"

#带域名访问,可以看到已经proxy到后端服务
curl http://127.0.0.1/ -H "Host: a.com"
curl http://127.0.0.1/ -H "Host: b.com"

#consul中注入相应域名的健康检查规则
curl -X PUT --data '{"type":"tcp"}' "http://127.0.0.1:8500/v1/kv/zlb_healthcheck/a.com"
curl -X PUT --data '{"type":"http","uri":"/health","valid"}' "http://127.0.0.1:8500/v1/kv/zlb_healthcheck/a.com"

JSON 格式如下
{ 
  "type":"检查类型（http|tcp）",
  "uri":"检查类型为http时，检查的uri路径。",
  "valid_statuses":"检查类型为http时，标记为有效的http返回状态码。多个状态码用,号隔开",
  "interval":"健康检查的间隔时间，单位毫秒，默认为2000",
  "timeout":"健康检查的网络超时时间，单位毫秒，默认为1000",
  "fall":"检查时连续失败多少次计为该后端节点不可用，默认为3",
  "ris":"对于不可用节点检查成功后连续多少次将该节点恢复为健康状态，默认为2",
  "concurrency":"健康检查时的并发线程数"
 }

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


#consul中注入需要过滤的Cookie,对于userid为u1的cookie不拦截，对于userid未u2的cookie拦截，灰度tag1版本迅速回切到生产环境，
#灰度版本tag2 按照灰度规则进行反向代理
curl -X PUT --data "0" "http://127.0.0.8500/v1/kv/zlb_cookiefilter/a.com/userid/u1"
curl -X PUT --data "1" "http://127.0.0.8500/v1/kv/zlb_cookiefilter/a.com/userid/u2"
curl -X PUT --data "1" "http://127.0.0.8500/v1/kv/zlb_cookiefilter/a.com/X_GRAY_TAG/tag1"
curl -X PUT --data "0" "http://127.0.0.8500/v1/kv/zlb_cookiefilter/a.com/X_GRAY_TAG/tag2"

#查看Cookie过滤规则
curl http://127.0.0.1/zlb_cookiefilter
{"a.com":{"X_GRAY_TAG":{"tag1":"1","tag2":"0"},"userid":{"u1":"0","u2":"1"}}}

#带Cookie验证Cookie过滤功能
curl http://127.0.0.1/ -H "Host: a.com" -b "X_GRAY_TAG=tag; userid=u1; a=c"
``` 

