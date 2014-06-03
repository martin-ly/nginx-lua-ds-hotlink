local config=require("config")
fd = io.open(config.logs_pwd.."hotlink.log","ab")

local function get_user_ip()
    local req_headers = ngx.req.get_headers()
    return (req_headers["X-Real-IP"] or req_headers["X_Forwarded_For"]) or ngx.var.remote_addr
end

local function log(args)
   local req_headers = ngx.req.get_headers()
   local time=ngx.localtime()
   local user_ip = get_user_ip()
   local method=ngx.req.get_method()
   local request_uri=ngx.var.request_uri
   local user_agent=ngx.var.http_user_agent or "-"
   local http_version=ngx.req.http_version()
   local header_refer=req_headers["Referer"] or "-"
   local key=ngx.var.arg_key or "-"
   local line = "["..args.module_name.."] "..user_ip.." ["..time.."] \""..method.." "..request_uri.." "..http_version.."\" \""..user_agent.."\" \""..
header_refer.."\" \""..key.."\"\n"
   fd:write(line)
   fd:flush()
end

---------------------------------------------------------------------------------

function hotlink_get_key()
    local path=ngx.var.arg_path
    if not path then
        ngx.exit(405)
    end
    local time=ngx.now()
    local string=time..path
    local digest = ngx.hmac_sha1(config.secret_key, string)
    ngx.say(ngx.encode_base64(time..":"..digest))
end

function hotlink_refer_module()
    local header_refer=ngx.req.get_headers()["Referer"]
    if header_refer~=nil then
        for _,white_domain in ipairs(config.white_domains) do
            if ngx.re.match(header_refer,white_domain,"isjo") then
                return
            end
        end
    end
    log{module_name="HOTLINK_REFER_MODULE"}
    ngx.exit(405)
end

function hotlink_accesskey_module()
    local key=ngx.var.arg_key
    if not key then
        log{module_name="HOTLINK_ACCESSKEY_MODULE"}
        ngx.exit(405)
    end
    local uri=ngx.var.request_uri
    local path=nil
    for i in string.gmatch(uri, "[^\\?]+") do 
        path=i
        break
    end
    local time_digest=ngx.decode_base64(key)
    if not time_digest:match(":") then
        log{module_name="HOTLINK_ACCESSKEY_MODULE"}
        ngx.exit(405)
    end
    local tmp_dic_time_digest={}
    for i in string.gmatch(time_digest,"[^\\:]+") do
        table.insert(tmp_dic_time_digest,i)
    end
    local time=tmp_dic_time_digest[1]
    local digest=tmp_dic_time_digest[2]
    if not time or not tonumber(time) or not digest or time+config.expiration_time < ngx.now() then
        log{module_name="HOTLINK_ACCESSKEY_MODULE"}
        ngx.exit(405)
    end
    local string=time..path
    local real_digest = ngx.hmac_sha1(config.secret_key, string)
    if digest ~=real_digest then
        log{module_name="HOTLINK_ACCESSKEY_MODULE"}
        ngx.exit(405)
    end

    return
end
