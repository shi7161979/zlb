local cjson = require("cjson")
local servername = ngx.var.server_name;
local lrucache = require "resty.lrucache"
local c, err = lrucache.new(400)
if not c then
    return error("failed to create the cache: " .. (err or "unknown"))
end
local cookiefilter =  c:get(servername)
if cookiefilter == nil then
    local str = ngx.shared.cookiefilter:get(servername);   
    ngx.log(ngx.ERR,servername.."="..str)
    if str ~= nil then
       cookiefilter = cjson.decode(str);
    else
       cookiefilter = {}
    end
    c:set(servername,cookiefilter)
end
local cookiestr = ngx.var.http_cookie;
if cookiestr ~= nil then
    ngx.log(ngx.ERR,"src cookie="..cookiestr);
    for k, rule in pairs(cookiefilter) do
    	for v,lifecycle in pairs(rule) do
        	if lifecycle ~= "0" or lifecycle ~= 0 then
                   cookiestr = string.gsub(cookiestr,k.."="..v..";", "")
                end
        end
    end
    ngx.var.vcookie = cookiestr
    ngx.log(ngx.ERR,"cookie="..cookiestr);
end
local t = ngx.var.cookie_X_GRAY_TAG 
if t == nil or t == 0 or t == "0"  then
    ngx.log(ngx.ERR,"vhost=".."."..servername);
    ngx.var.vhost = t.."."..servername      
end
