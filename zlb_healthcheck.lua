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
     local type = value["Type"];
     local httpstatus = {};
     local uri = "";
     if value["Uri"] ~= nil and type == "http" and value["Valid_statuses"] ~= nil then
         uri = value["Uri"]
         httpstatus = value["Valid_statuses"]:split(",")
     end
     if type == nil then
        type = "tcp"     
     end
     local interval = 2000;
     if value["Interval"] ~= nil then
         interval =  tonumber(value["Interval"]);
     end
     local timeout = 1000;     
     if value["Timeout"] ~= nil then
         timeout = tonumber(value["Timeout"]);
     end
     local fall = 3;
     if value["Fall"] ~= nil then
        fall = tonumber(value["Fall"]);
     end
     local rise = 2;
     if value["Rise"] ~= nil then
        rise = tonumber(value["Rise"]);
     end 
     local concurrency = 10;
     if value["Concurrency"] ~= nil then
        concurrency = tonumber(value["Concurrency"])
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

