local hc = require "resty.upstream.healthcheck"
local cjson = require "cjson";

local function getJsonParas(filepath)
    local cfgfile,err = io.open(filepath,"r");
    local content = {}
    if cfgfile ~= nil then
    	local jsonstr = cfgfile:read("*all");
    	jsonstr = (string.gsub(jsonstr, "%s+", ""))
    	jsonstr = (string.gsub(jsonstr, "\r+", ""))
    	jsonstr = (string.gsub(jsonstr, "\n+", ""))
    	jsonstr = (string.gsub(jsonstr, ",}", "}")) 
    	content = cjson.decode(jsonstr);
    	cfgfile:close()  
    end 
    return content    
end

function string:split(sep)  
    local sep, fields = sep or ":", {}  
    local pattern = string.format("([^%s]+)", sep)  
    self:gsub(pattern, function (c) fields[#fields + 1] = c end)  
    return fields  
end

-- set cookefilter paras
ckfilterpara = getJsonParas("/usr/local/openresty/nginx/cookiefilter.json");

-- set healthcheck paras
local content = getJsonParas("/usr/local/openresty/nginx/healthcheck.json");
if ngx.shared.healthcheck ~= nil then
  ngx.shared.healthcheck:flush_all();
end
for domain,v in pairs(content) do
     ngx.log(ngx.WARN,domain.."="..v);   
     local value = cjson.decode(v);
     local type = value["type"];
     local httpstatus = {};
     local uri = "";
     if value["uri"] ~= nil and type == "http" and value["valid_statuses"] ~= nil then
         uri = value["uri"]
         httpstatus = value["valid_statuses"]:split(",")
     end
     if type == nil then
        type = "tcp"     
     end
     local interval = 2000;
     if value["interval"] ~= nil then
         interval =  tonumber(value["interval"]);
     end
     local timeout = 1000;     
     if value["timeout"] ~= nil then
         timeout = tonumber(value["timeout"]);
     end
     local fall = 3;
     if value["fall"] ~= nil then
        fall = tonumber(value["fall"]);
     end
     local rise = 2;
     if value["rise"] ~= nil then
        rise = tonumber(value["rise"]);
     end 
     local concurrency = 10;
     if value["concurrency"] ~= nil then
        concurrency = tonumber(value["concurrency"])
     end     

     local ok, err = hc.spawn_checker{     
          shm = "healthcheck",
          upstream = domain,
          type = type,
          http_req =  "HEAD "..uri.." HTTP/1.0\r\nHost: "..domain.."\r\n\r\n",
          interval = interval,
          timeout = timeout,
          fall = fall,
          rise = rise,
          valid_statuses = httpstatus,
          concurrency = concurrency
     }
end

