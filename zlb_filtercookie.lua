local cjson = require("cjson")
local servername = ngx.var.server_name;

local function is_include(value, tbl)
    for _,v in ipairs(tbl) do
      if v == value then
          return true
      end
    end
    return false
end

local cookiefilter = {}
if ckfilterpara ~= nil then
	cookiefilter =  ckfilterpara[servername]
	if cookiefilter == nil then
        	cookiefilter = {};
	end
end
local cookiestr = ngx.var.http_cookie;
if cookiestr ~= nil then
    for k, rule in pairs(cookiefilter) do
    	for v,lifecycle in pairs(rule) do
                if lifecycle ~= "0" and lifecycle ~= 0 then
                   cookiestr = string.gsub(cookiestr,"%s?"..k.."="..v..";?", "")
                end
        end
    end
    ngx.var.vcookie = cookiestr
    local i,j= string.find(cookiestr,"X_GRAY_TAG=([^;]+)") 
    if i ~= nil then
        local t = string.sub(cookiestr,i+string.len("X_GRAY_TAG="),j)       
        local vhost = t.."."..ngx.var.vhost;
        local upstream = require "ngx.upstream"
        local get_servers = upstream.get_servers
        local get_upstreams = upstream.get_upstreams
        local us = get_upstreams()
        if is_include(vhost,us) then  
            ngx.var.vhost = vhost
        end
    end
    ngx.log(ngx.ERR,"upstream Host:"..ngx.var.vhost..",".."cookie:"..ngx.var.vcookie)
end
