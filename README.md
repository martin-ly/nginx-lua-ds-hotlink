nginx-lua-ds-hotlink
====================

基于nginx和lua的防盗链系统

A Prevent Hotlinking System based on openresty/lua-nginx-module

将代码放在位于nginx根目录下的lua/ds_hotlink/下

Put the code into the directory lua/ds_hotlink which is located in the root directory of the nginx

在nginx.conf的http段中添加如下配置：

Add the config below to the http seg in nginx.conf:

        lua_package_path "/u/nginx/lua/ds_hotlink/?.lua;;";
        init_by_lua_file lua/ds_hotlink/init.lua;

配置如下location用于获取访问key

Add the config below to /get_key location for geting access key

        location = /get_key {
            allow 10.0.2.2;
            deny all;
            content_by_lua_file lua/ds_hotlink/get_key.lua;
        }
        
在需要防盗链的location下配置如下

Add the config below to a location which need to prevent hotlinking

        access_by_lua_file lua/ds_hotlink/refer.lua;

或者配置如下

Alternative config below

        access_by_lua_file lua/ds_hotlink/accesskey.lua;

防盗链相关的配置在config.lua中，需要保证nginx的worker process对日志文件有读写权限

You can config Prevent Hotlinking System with the file config.lua,and you must make the worker process of nginx have the read and write permission to the log file
