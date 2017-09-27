FROM openresty/openresty:centos-rpm

MAINTAINER zanecloud

RUN curl -kv -o /usr/local/bin/consul-template  http://zanecloud-docker.oss-cn-shanghai.aliyuncs.com/consul-template

ADD nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

ADD healthcheck.lua /usr/local/openresty/lualib/resty/upstream/healthcheck.lua

RUN mkdir -p /opt/zlb/

RUN touch /opt/zlb/zlb.conf

ADD create.lua zlb_filtercookie.lua zlb.json.ctmpl  /opt/zlb/

ADD startup.sh restart.sh /usr/local/bin/

RUN cd /usr/local/bin/ && chmod u+x startup.sh && chmod u+x restart.sh && chmod u+x consul-template

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/startup.sh"]
