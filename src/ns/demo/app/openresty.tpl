envFrom:
  secret:
    secrets:
      MY_SECRET: my_secret

file:
  /usr/local/openresty/nginx/conf:
    nginx.conf: |
      env MY_SECRET;
      http {
        server {
            location / {
                content_by_lua_block {
                    ngx.say("MY_SECRET: " .. os.getenv("MY_SECRET"))
                }
            }
            listen 80;
        }
      }
      events {
          worker_connections 1024;
      }

podAnnotations:
  up: ""
