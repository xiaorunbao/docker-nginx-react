#!/bin/sh

echo "setting nginx conf ..."
echo "DEBUG: $DEBUG"
echo "BUILD: $BUILD"
echo "ENV_PREFIX: $ENV_PREFIX"
echo "WHITE_LIST: ${WHITE_LIST}"
echo "WHITE_LIST_IP: ${WHITE_LIST_IP}"
echo "APP_VERSION: ${APP_VERSION}"
echo "APP_WORKDIR: ${APP_WORKDIR}"
echo "APP_BASENAME: ${APP_BASENAME}"
echo "CLIENT_BODY_TIMEOUT: ${CLIENT_BODY_TIMEOUT}"
echo "CLIENT_HEADER_TIMEOUT: ${CLIENT_HEADER_TIMEOUT}"
echo "CLIENT_MAX_BODY_SIZE: ${CLIENT_MAX_BODY_SIZE}"

# Replace env for nginx conf
envsubst \
  '$DEBUG $BUILD $WHITE_LIST $WHITE_LIST_IP $APP_VERSION $APP_WORKDIR \
$APP_BASENAME $CLIENT_BODY_TIMEOUT $CLIENT_HEADER_TIMEOUT $CLIENT_MAX_BODY_SIZE' \
  < /etc/nginx/conf.d/app.conf.template > /etc/nginx/conf.d/default.conf

# Delete white list config if white list feature is off
if [ "${WHITE_LIST}" = 'off' ]; then
  sed -i '/^[[:space:]]*#[[:space:]]*BEGIN_CONFIG_WHEN_WHITE_LIST_ON/,/^[[:space:]]*#[[:space:]]*END_CONFIG_WHEN_WHITE_LIST_ON/d' /etc/nginx/conf.d/default.conf
fi

# Inject runtime env into *.html files
ENV_SUBS=$(env | cut -d= -f1 | grep "^${ENV_PREFIX}" | sed -e 's/^/\$/')
echo "inject runtime environments ..."

# Recreate env-runtime file
rm -rf ./env-runtime.js
touch ./env-runtime.js

# Build runtime environment JavaScript object
echo "window._runtime_ = {" >> ./env-runtime.js
for e in $ENV_SUBS; do
  eName=$(echo "$e" | sed -e 's/^\$//')
  value=$(eval echo "\"\$${eName}\"")
  printf '  %s: "%s",\n' "$eName" "$value" >> ./env-runtime.js
done
echo "}" >> ./env-runtime.js

# Inject env-runtime.js script tag into HTML files
sed -i \
  -e 's/<script src="\/env-runtime.js"><\/script>//g' \
  -e 's/<body>/&<script src="\/env-runtime.js"><\/script>/' \
  *.html

# Start nginx
echo "start nginx"
nginx -g 'daemon off;'
exec "$@"