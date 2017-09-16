#!/bin/bash
NGINX=/usr/local/openresty/nginx/sbin/nginx
NGINX_CONF=/usr/local/openresty/nginx/conf/nginx.conf
ZLB_TEMPLATE=/usr/local/openresty/nginx/conf.d/zlb.conf.ctmpl
ZLB_CONF=/usr/local/openresty/nginx/conf.d/zlb.conf

ZLB_CHECKJSON_TEMPLATE=/usr/local/openresty/nginx/healthcheck.json.ctmpl
ZLB_CHECKJSON=/usr/local/openresty/nginx/healthcheck.json

ZLB_CKFILTERJSON_TEMP=/usr/local/openresty/nginx/cookiefilter.json.ctmpl
ZLB_CKFILTERJSON=/usr/local/openresty/nginx/cookiefilter.json

CONSUL_8500_TCP_ADDR=${CONSUL_8500_TCP_ADDR:-127.0.0.1:8500}
RESTART_COMMAND=/usr/local/bin/restart.sh

# set initial data to consul key-value store
# start nginx with default setting
${NGINX} -c ${NGINX_CONF} -g "daemon on;"

# start consul-template
/usr/local/bin/consul-template -consul-addr ${CONSUL_8500_TCP_ADDR:-127.0.0.1:8500} -template "${ZLB_CKFILTERJSON_TEMP}:${ZLB_CKFILTERJSON}:${RESTART_COMMAND} || true" -template "${ZLB_CHECKJSON_TEMPLATE}:${ZLB_CHECKJSON}:${RESTART_COMMAND} || true" -template "${ZLB_TEMPLATE}:${ZLB_CONF}:${RESTART_COMMAND} || true"  
