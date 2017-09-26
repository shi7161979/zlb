local cjson = require("cjson")
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
zlbcfg = getJsonParas("/opt/zlb/zlb.json");
local healthchecks = {};
local servers = zlbcfg["servers"]
for domain,v in pairs(servers) do
    for path, server in pairs(v) do
       local p = string.gsub(ngx.decode_base64(path),"/","_");
       local upstream = domain..p
       ngx.say("upstream "..upstream.." {") 
       for host, _ in pairs(server) do
          ngx.say("  server "..host..";")
       end
       local keepalive = 10;
       local sticky = false;
       local cfg = zlbcfg["cfgs"][domain]
       local healthcheck = {}
       if cfg ~=nil then
            local cfgnode= cfg[path];
            if cfgnode == nil and path ~= "Lw=" then
                cfgnode = cfg["Lw=="]
            end
            if cfgnode ~= nil then
                local cfgjson = cjson.decode(cfgnode)
                if cfgjson["KeepAlive"] ~= nil then
                   keepalive = cfgjson["KeepAlive"]
                end
                if cfgjson["Sticky"] ~= nil then
                   sticky = cfgjson["Sticky"]
                end 
                if cfgjson["Healthcheck"] ~= nil then
                   healthcheck = cfgjson["Healthcheck"]
                end
            end           
       end
       healthcheck["domain"] = domain
       ngx.say("  keepalive "..keepalive..";");
       if sticky then
          --ngx.say("  sticky;")
       end
       ngx.say("}\n");
       healthchecks[upstream]=healthcheck;  
   end
end

ngx.say("lua_shared_dict healthcheck 10m;\n");
ngx.say("lua_socket_log_errors off;\n");
ngx.say("init_worker_by_lua_block { ")
ngx.say("  local hc = require \"resty.upstream.healthcheck\";");
ngx.say("  local cjson = require \"cjson\";");
ngx.say("  ckfilterpara=cjson.decode('"..cjson.encode(zlbcfg["ckfilters"]).."');");

for upstream,value in pairs(healthchecks) do
     local type = value["Type"];
     local httpstatus = "";
     local uri = "";
     if value["Uri"] ~= nil and type == "http" and value["Valid_statuses"] ~= nil then
         uri = value["Uri"]
         httpstatus = value["Valid_statuses"];
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
     ngx.say(" local ok, err = hc.spawn_checker{")
     ngx.say("       shm = \"healthcheck\",")
     ngx.say("       upstream = \""..upstream.."\",")
     ngx.say("       type = \""..type.."\",")
     if type == "http" then
        ngx.say("       http_req =  \"HEAD "..uri.." HTTP/1.0\\r\\nHost: "..value["domain"].."\\r\\n\\r\\n\",")
        ngx.say("       valid_statuses = {"..httpstatus.."},")
     else 
        ngx.say("       http_req = \"\",")
        ngx.say("       valid_statuses = {},")
     end
     ngx.say("       interval = "..interval..",")
     ngx.say("       timeout = "..timeout..",")
     ngx.say("       fall = "..fall..",")
     ngx.say("       rise = "..rise..",")
     ngx.say("       concurrency = "..concurrency);
     ngx.say(" }; \n");      
end
ngx.say("}\n")

for domain,v in pairs(servers) do
    ngx.say(" server {");
    ngx.say("    listen 80;");
    ngx.say("    server_name "..domain..";");
    for path, server in pairs(v) do
       local l = ngx.decode_base64(path)
       ngx.say("\n    location "..l.." { ");
       ngx.say("      set $vhost   \""..domain..string.gsub(l,"/","_").."\";");
       ngx.say("      set $vcookie \"\";");
       ngx.say("      rewrite_by_lua_file /opt/zlb/zlb_filtercookie.lua;")
       ngx.say("      proxy_pass http://$vhost;");
       ngx.say("      proxy_http_version 1.1;");
       ngx.say("      proxy_set_header Connection \"\";");
       ngx.say("      proxy_set_header Cookie $vcookie;");
       ngx.say("    }\n");    
    end
    ngx.say(" }");
end
