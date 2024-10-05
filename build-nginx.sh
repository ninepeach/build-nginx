#!/usr/bin/env bash
# Run as root or with sudo
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Ensure curl is installed
#apt-get update && apt-get install curl -y

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
opgp_openssl_1=8657ABB260F056B1E5190839D9C4D26D0E604491 #Matt Caswell
opgp_openssl_2=B7C1C14360F353A36862E4D5231C84CDDCC69C45 #Paul Dale
opgp_openssl_3=7953AC1FBC3DC8B3B292393ED5E9E43F7DF9EE8C #Richaard Levitte
opgp_openssl_4=A21FAB74B0088AA361152586B8EF1A6BA9DA2D5C #Tomas Mrax
opgp_openssl_5=EFC0A467D613CB83C7ED6D30D894E2CE8B3D79F5 #OpenSSL OMC
opgp_nginx=13C82A63B603576156E30A4EA0EA981B66B0D967

# Set where OpenSSL and NGINX will be built
bpath=$(pwd)/build
install_path=/usr/local/nginx

# Make a "today" variable for use in back-up filenames later
today=$(date +"%Y-%m-%d")

# Ensure the required software to compile NGINX is installed
apt-get -y install \
  binutils \
  build-essential \
  curl \
  dirmngr \
  libssl-dev

# Download the source files
if [ -f "${bpath}/${version_pcre}.tar.gz" ]; then
    echo "${version_pcre}.tar.gz"  already downloaded
else
    echo curl -L "${source_pcre}${version_pcre}.tar.gz" -o "${bpath}/${version_pcre}.tar.gz"
    curl -L "${source_pcre}${version_pcre}.tar.gz" -o "${bpath}/${version_pcre}.tar.gz"
fi

if [ -f "${bpath}/${version_zlib}.tar.gz" ]; then
    echo "${version_zlib}.tar.gz"  already downloaded
else
    echo curl -L "${source_zlib}${version_zlib}.tar.gz" -o "${bpath}/${version_zlib}.tar.gz"
    curl -L "${source_zlib}${version_zlib}.tar.gz" -o "${bpath}/${version_zlib}.tar.gz"
fi

if [ -f "${bpath}/${version_openssl}.tar.gz" ]; then
    echo "${version_openssl}.tar.gz"  already downloaded
else
    echo curl -L "${source_openssl}${version_openssl}.tar.gz" -o "${bpath}/${version_openssl}.tar.gz"
    curl -L "${source_openssl}${version_openssl}.tar.gz" -o "${bpath}/${version_openssl}.tar.gz"
fi

if [ -f "${bpath}/${version_nginx}.tar.gz" ]; then
    echo "${version_nginx}.tar.gz"  already downloaded
else
    echo curl -L "${source_nginx}${version_nginx}.tar.gz" -o "${bpath}/${version_nginx}.tar.gz"
    curl -L "${source_nginx}${version_nginx}.tar.gz" -o "${bpath}/${version_nginx}.tar.gz"
fi

# Download the signature files
if [ -f "${bpath}/${version_pcre}.tar.gz.sig" ]; then
    echo "${version_pcre}.tar.gz.sig"  already downloaded
else
    echo curl -L "${source_pcre}${version_pcre}.tar.gz.sig" -o "${bpath}/${version_pcre}.tar.gz.sig"
    curl -L "${source_pcre}${version_pcre}.tar.gz.sig" -o "${bpath}/${version_pcre}.tar.gz.sig"
fi

if [ -f "${bpath}/${version_zlib}.tar.gz.asc" ]; then
    echo "${version_zlib}.tar.gz.asc"  already downloaded
else
    echo curl -L "${source_zlib}${version_zlib}.tar.gz.asc" -o "${bpath}/${version_zlib}.tar.gz.asc"
    curl -L "${source_zlib}${version_zlib}.tar.gz.asc" -o "${bpath}/${version_zlib}.tar.gz.asc"
fi

if [ -f "${bpath}/${version_openssl}.tar.gz.asc" ]; then
    echo "${version_openssl}.tar.gz.asc"  already downloaded
else
    echo curl -L "${source_openssl}${version_openssl}.tar.gz.asc" -o "${bpath}/${version_openssl}.tar.gz.asc"
    curl -L "${source_openssl}${version_openssl}.tar.gz.asc" -o "${bpath}/${version_openssl}.tar.gz.asc"
fi

if [ -f "${bpath}/${version_nginx}.tar.gz.asc" ]; then
    echo "${version_nginx}.tar.gz.asc"  already downloaded
else
    echo curl -L "${source_nginx}${version_nginx}.tar.gz.asc" -o "${bpath}/${version_nginx}.tar.gz.asc"
    curl -L "${source_nginx}${version_nginx}.tar.gz.asc" -o "${bpath}/${version_nginx}.tar.gz.asc"
fi

# Verify the integrity and authenticity of the source files through their OpenPGP signature
cd "$bpath"
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
gpg --keyserver keyserver.ubuntu.com --recv-keys "$opgp_pcre" "$opgp_zlib" "$opgp_openssl_1" "$opgp_openssl_2" "$opgp_openssl_3" "$opgp_openssl_4" "$opgp_openssl_5" "$opgp_nginx"
gpg --batch --verify ${version_pcre}.tar.gz.sig ${version_pcre}.tar.gz
gpg --batch --verify ${version_zlib}.tar.gz.asc ${version_zlib}.tar.gz
gpg --batch --verify ${version_openssl}.tar.gz.asc ${version_openssl}.tar.gz
gpg --batch --verify ${version_nginx}.tar.gz.asc ${version_nginx}.tar.gz


# Clean up source files
rm -rf \
  "$bpath"/${version_zlib} \
  "$bpath"/${version_pcre} \
  "$bpath"/${version_openssl} \
  "$bpath"/${version_nginx}

# Expand the source files
cd "$bpath"
for archive in ./*.tar.gz; do
  tar xzf "$archive"
  echo tar xzf "$archive"
done


# Clean up source files
rm -rf \
  "$GNUPGHOME"

# Rename the existing /etc/nginx directory so it's saved as a back-up
if [ -d "${install_path}/etc/nginx" ]; then
  mv ${install_path}/etc/nginx "${install_path}/etc/nginx-${today}"
fi

# Create NGINX cache directories if they do not already exist
if [ ! -d "${install_path}/var/cache/nginx/" ]; then
  mkdir -p \
    ${install_path}/var/cache/nginx/client_temp \
    ${install_path}/var/cache/nginx/proxy_temp \
    ${install_path}/var/cache/nginx/fastcgi_temp \
    ${install_path}/var/cache/nginx/uwsgi_temp \
    ${install_path}/var/cache/nginx/scgi_temp
fi

# Test to see if our version of gcc supports __SIZEOF_INT128__
if gcc -dM -E - </dev/null | grep -q __SIZEOF_INT128__
then
  ecflag="enable-ec_nistp_64_gcc_128"
else
  ecflag=""
fi

# Build NGINX, with various modules included/excluded
cd "$bpath/$version_nginx"
./configure \
  --prefix=${install_path}/etc/nginx \
  --with-cc-opt="-O3 -fPIE -fstack-protector-strong -Wformat -Werror=format-security" \
  --with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro" \
  --with-pcre="$bpath/$version_pcre" \
  --with-zlib="$bpath/$version_zlib" \
  --with-openssl-opt="no-weak-ssl-ciphers no-ssl3 no-shared $ecflag -DOPENSSL_NO_HEARTBEATS -fstack-protector-strong" \
  --with-openssl="$bpath/$version_openssl" \
  --sbin-path=${install_path}/sbin/nginx \
  --modules-path=${install_path}/lib/nginx/modules \
  --conf-path=${install_path}/etc/nginx/nginx.conf \
  --error-log-path=${install_path}/var/log/nginx/error.log \
  --http-log-path=${install_path}/var/log/nginx/access.log \
  --pid-path=${install_path}/var/run/nginx.pid \
  --lock-path=${install_path}/var/run/nginx.lock \
  --http-client-body-temp-path=${install_path}/var/cache/nginx/client_temp \
  --http-proxy-temp-path=${install_path}/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=${install_path}/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=${install_path}/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=${install_path}/var/cache/nginx/scgi_temp \
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

if [ -d "${install_path}/etc/nginx-${today}" ]; then
  # Rename the default /etc/nginx settings directory so it's accessible as a reference to the new NGINX defaults
  mv ${install_path}/etc/nginx ${install_path}/etc/nginx-default

  # Restore the previous version of /etc/nginx to /etc/nginx so the old settings are kept
  mv "${install_path}/etc/nginx-${today}" ${install_path}/etc/nginx
fi

# Create NGINX systemd service file if it does not already exist
if [ ! -e "${install_path}/service/nginx.service" ]; then
  # Control will enter here if the NGINX service doesn't exist.
  file="${install_path}/service/nginx.service"

  mkdir -p ${file}
  /bin/cat >$file <<'EOF'
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/var/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
fi

# Create NGINX systemd service file if it does not already exist
if [ ! -e "${install_path}/service/README" ]; then
  # Control will enter here if the NGINX service doesn't exist.
  file="${install_path}/service/README"

  mkdir -p ${file}
  /bin/cat >$file <<'EOF'

# Add NGINX group and user if they do not already exist
id -g nginx &>/dev/null || addgroup --system nginx
id -u nginx &>/dev/null || adduser --disabled-password --system --shell /sbin/nologin --group nginx

cp /usr/local/nginx/service/nginx.service /lib/systemd/system/nginx.service
systemctl start nginx.service
EOF
fi


echo "All done.";
echo "pls read ${install_path}/README"
