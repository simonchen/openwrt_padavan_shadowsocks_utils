## 安装Shellinabox
复制本目录全部文件到/etc/storage/
运行下面命令，执行安装:
<pre>
cd /etc/storage && chmod +x setup.sh && ./setup.sh restart http
</pre>
安装后可访问路由http://{your router ip}:4200 , 如果用https，改上述命令`http`为`https`
