#!/bin/sh
curl -o /opt/zlb/zlb.conf  http://127.0.0.1/zlb_create
/usr/local/openresty/nginx/sbin/nginx -s reload
