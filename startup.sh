#!/bin/bash
NGINX=/usr/local/openresty/nginx/sbin/nginx
NGINX_CONF=/usr/local/openresty/nginx/conf/nginx.conf
ZLB_TEMPLATE=/opt/zlb/zlb.json.ctmpl
ZLB_JSON=/opt/zlb/zlb.json

CONSUL_8500_TCP_ADDR=${CONSUL_8500_TCP_ADDR:-127.0.0.1:8500}
RESTART_COMMAND=/usr/local/bin/restart.sh

# set initial data to consul key-value store
# start nginx with default setting
${NGINX} -c ${NGINX_CONF} -g "daemon on;"

# start consul-template
/usr/local/bin/consul-template -consul-addr ${CONSUL_8500_TCP_ADDR:-127.0.0.1:8500} -template "${ZLB_TEMPLATE}:${ZLB_JSON}:${RESTART_COMMAND} || true"
