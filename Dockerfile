FROM openresty/openresty:centos-rpm

MAINTAINER zanecloud

RUN curl -o /usr/local/bin/consul-template  http://zanecloud-docker.oss-cn-shanghai.aliyuncs.com/consul-template

RUN mkdir -p /usr/local/openresty/nginx/conf.d/

ADD nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

ADD zlb.conf.ctmpl /usr/local/openresty/nginx/conf.d/zlb.conf.ctmpl

ADD healthcheck.json.ctmpl /usr/local/openresty/nginx/healthcheck.json.ctmpl

ADD healthcheck.lua /usr/local/openresty/lualib/resty/upstream/healthcheck.lua

ADD zlb_healthcheck.lua  /usr/local/openresty/nginx/zlb_healthcheck.lua

ADD startup.sh restart.sh /usr/local/bin/

RUN cd /usr/local/bin/ && chmod u+x startup.sh && chmod u+x restart.sh && chmod u+x consul-template

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/startup.sh"]
