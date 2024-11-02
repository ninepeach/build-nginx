#!/usr/bin/env bash
# Run as root or with sudo
if [ $EUID -ne 0 ]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Ensure curl and required packages are installed
apt-get update && apt-get install curl -y
mkdir -p build

# Set URLs to the source directories
source_pcre=https://onboardcloud.dl.sourceforge.net/project/pcre/pcre/8.45/
source_zlib=https://zlib.net/
source_openssl=https://www.openssl.org/source/
source_nginx=https://nginx.org/download/

# Look up latest versions of each package
version_pcre=pcre-8.45
version_zlib=zlib-1.3.1
version_openssl=openssl-3.3.2
version_nginx=nginx-1.26.2

# Set OpenPGP keys used to sign downloads
opgp_pcre=45F68D54BBE23FB3039B46E59766E084FB0F43D8
opgp_zlib=5ED46A6721D365587791E2AA783FCD8E58BCAFBA
opgp_openssl_1=8657ABB260F056B1E5190839D9C4D26D0E604491
opgp_openssl_2=B7C1C14360F353A36862E4D5231C84CDDCC69C45
opgp_openssl_3=7953AC1FBC3DC8B3B292393ED5E9E43F7DF9EE8C
opgp_openssl_4=A21FAB74B0088AA361152586B8EF1A6BA9DA2D5C
opgp_openssl_5=EFC0A467D613CB83C7ED6D30D894E2CE8B3D79F5
opgp_nginx=13C82A63B603576156E30A4EA0EA981B66B0D967

# Set where OpenSSL and NGINX will be built
bpath=$(pwd)/build
srcPath=$(pwd)/src
install_path=/usr/local/nginx

# Make a "today" variable for use in back-up filenames later
today=$(date +"%Y-%m-%d")

# Ensure the required software to compile NGINX and PHP are installed
apt-get -y install \
  binutils \
  build-essential \
  curl \
  dirmngr \
  libssl-dev \
  php-fpm \
  php-cli \
  php-mysql

# Download the source files
if [ -f "${srcPath}/${version_pcre}.tar.gz" ]; then
    echo "${version_pcre}.tar.gz" already downloaded
else
    curl -L "${source_pcre}${version_pcre}.tar.gz" -o "${srcPath}/${version_pcre}.tar.gz"
fi

if [ -f "${srcPath}/${version_zlib}.tar.gz" ]; then
    echo "${version_zlib}.tar.gz" already downloaded
else
    curl -L "${source_zlib}${version_zlib}.tar.gz" -o "${srcPath}/${version_zlib}.tar.gz"
fi

if [ -f "${srcPath}/${version_openssl}.tar.gz" ]; then
    echo "${version_openssl}.tar.gz" already downloaded
else
    curl -L "${source_openssl}${version_openssl}.tar.gz" -o "${srcPath}/${version_openssl}.tar.gz"
fi

if [ -f "${srcPath}/${version_nginx}.tar.gz" ]; then
    echo "${version_nginx}.tar.gz" already downloaded
else
    curl -L "${source_nginx}${version_nginx}.tar.gz" -o "${srcPath}/${version_nginx}.tar.gz"
fi

# Verify the integrity and authenticity of the source files
cd "$srcPath"
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
gpg --keyserver keyserver.ubuntu.com --recv-keys "$opgp_pcre" "$opgp_zlib" "$opgp_openssl_1" "$opgp_openssl_2" "$opgp_openssl_3" "$opgp_openssl_4" "$opgp_openssl_5" "$opgp_nginx"
gpg --batch --verify ${version_pcre}.tar.gz.sig ${version_pcre}.tar.gz
gpg --batch --verify ${version_zlib}.tar.gz.asc ${version_zlib}.tar.gz
gpg --batch --verify ${version_openssl}.tar.gz.asc ${version_openssl}.tar.gz
gpg --batch --verify ${version_nginx}.tar.gz.asc ${version_nginx}.tar.gz

cd "$bpath"
# Clean up source files
rm -rf \
  "$bpath"/${version_zlib} \
  "$bpath"/${version_pcre} \
  "$bpath"/${version_openssl} \
  "$bpath"/${version_nginx}

# Expand the source files
for archive in ../src/*.tar.gz; do
  tar xzf "$archive"
done

# Clean up GNUPGHOME
rm -rf \
  "$GNUPGHOME"

# Build NGINX with PHP-FPM support
cd "$bpath/$version_nginx"
./configure \
  --prefix=${install_path} \
  --with-cc-opt="-O3 -fPIE -fstack-protector-strong -Wformat -Werror=format-security" \
  --with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro" \
  --with-pcre="$bpath/$version_pcre" \
  --with-zlib="$bpath/$version_zlib" \
  --with-openssl-opt="no-weak-ssl-ciphers no-ssl3 no-shared $ecflag -DOPENSSL_NO_HEARTBEATS -fstack-protector-strong" \
  --with-openssl="$bpath/$version_openssl" \
  --sbin-path=${install_path}/sbin/nginx \
  --modules-path=${install_path}/lib/nginx/modules \
  --conf-path=${install_path}/etc/nginx/nginx.conf \
  --error-log-path=${install_path}/logs/error.log \
  --http-log-path=${install_path}/logs/access.log \
  --pid-path=${install_path}/run/nginx.pid \
  --lock-path=${install_path}/run/nginx.lock \
  --http-client-body-temp-path=${install_path}/cache/client_temp \
  --http-proxy-temp-path=${install_path}/cache/proxy_temp \
  --http-fastcgi-temp-path=${install_path}/cache/fastcgi_temp \
  --http-uwsgi-temp-path=${install_path}/cache/uwsgi_temp \
  --http-scgi-temp-path=${install_path}/cache/scgi_temp \
  --user=nginx \
  --group=nginx \
  --with-file-aio \
  --with-http_auth_request_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_mp4_module \
  --with-http_realip_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-pcre-jit \
  --with-stream \
  --with-stream_ssl_module \
  --with-threads \
  --without-http_empty_gif_module \
  --without-http_geo_module \
  --without-http_split_clients_module \
  --without-http_ssi_module \
  --without-mail_imap_module \
  --without-mail_pop3_module \
  --without-mail_smtp_module
make
make install
make clean
strip -s ${install_path}/sbin/nginx*

mkdir -p ${install_path}/etc/nginx/conf.d
mkdir -p ${install_path}/logs
mkdir -p ${install_path}/cache
mkdir -p ${install_path}/service

# PHP-FPM Configuration
echo "Configuring PHP-FPM..."

cat <<EOF > ${install_path}/etc/nginx/nginx.conf
user  nginx;
worker_processes auto;                   # Automatically select worker processes based on CPU
worker_rlimit_nofile 100000;              # Max file descriptors per worker
error_log logs/error.log crit;

events {
    worker_connections 8192;              # Max number of simultaneous connections per worker
    multi_accept on;                      # Accept multiple connections at once
    use epoll;                            # Use epoll for Linux
}

http {

    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    #access_log  logs/access.log  main;
    access_log /dev/null;

    # General Optimizations
    sendfile on;                          # Enables efficient file transfer
    tcp_nopush on;                        # Send headers in one packet
    tcp_nodelay on;                       # Minimize latency for keep-alive connections
    keepalive_timeout 65;                 # Timeout for keep-alive connections
    types_hash_max_size 2048;             # Increase MIME type hash table size

    # Buffers and Timeouts
    client_body_buffer_size 10K;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 16k;    # For handling large headers
    output_buffers 1 512k;
    postpone_output 1460;
    reset_timedout_connection on;

    # Gzip Compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_min_length 256;
    gzip_comp_level 5;
    gzip_vary on;

    ##
    # Virtual Host Configs
    ##

    include conf.d/*.conf;

}
EOF

cat <<EOF > ${install_path}/etc/nginx/conf.d/default.conf
server {
    listen       80;
    server_name  localhost;

    access_log  logs/access.log  main;

    location / {
        root   html;
        index  index.html index.htm index.php;
    }

    error_page  404              /404.html;
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
    
    location ~ \.php$ {
        root           html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;

        include        fastcgi_params;
    }
}
EOF

cat <<'EOF' > ${install_path}/service/install.sh 
#!/usr/bin/env bash

# Add NGINX group and user if they do not already exist
sudo id -g nginx &>/dev/null || sudo addgroup --system nginx
sudo id -u nginx &>/dev/null || sudo adduser --disabled-password --system --shell /sbin/nologin --group nginx

if [ ! -e "/lib/systemd/system/nginx.service" ]; then
sudo cp /usr/local/nginx/service/nginx.service /lib/systemd/system/nginx.service
sudo systemctl daemon-reload
sudo systemctl enable nginx
sudo systemctl start nginx
fi
EOF
chmod +x ${install_path}/service/install.sh

# Systemd service for NGINX if not exist
cat <<'EOF' > ${install_path}/service/nginx.service
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

chown -R nginx:nginx ${install_path}

# Print completion message
echo "NGINX has been installed and started successfully."
