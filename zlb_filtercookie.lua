local cjson = require("cjson")
local servername = ngx.var.server_name;
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
        ngx.var.vhost = t.."."..servername
    end
    ngx.log(ngx.ERR,"upstream Host:"..ngx.var.vhost..",".."cookie:"..ngx.var.vcookie)
end
