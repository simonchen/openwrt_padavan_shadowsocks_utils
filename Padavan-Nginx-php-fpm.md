## How to resolve "File not found"?
Please replace "/scripts' with $document_root 
<pre>
        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        location ~ \.php$ {
            root           /home/root/www;
            try_files  $uri =404;
            fastcgi_pass   127.0.0.1:9001;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
</pre>

## How to resolve "No input file specified"?
https://stackoverflow.com/questions/46028755/nginx-no-input-file-specified
<pre>
Okay the reason this configuration wasn't working is because aside from fastcgi_params you can also set php_value[doc_root] which will overwrite your $document_root which is commonly used in the SCRIPT_FILENAME parameter. So check your php.ini files always to make sure php_value[doc_root] is not set when you have apps that are being served from different directories otherwise it just wont pick them up. In the case that you are just serving a single app from a single directory you need not worry.
</pre>
