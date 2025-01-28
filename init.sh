#!/bin/bash

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping init"
    cd frappe-bench
    bench start
else
    echo "Creating new bench..."
    export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION_DEVELOP}/bin/:${PATH}"
    bench init --skip-redis-config-generation frappe-bench
    cd frappe-bench

    # Use containers instead of localhost
    bench set-mariadb-host mariadb
    bench set-redis-cache-host redis-cache:6379
    bench set-redis-queue-host redis-queue:6379
    bench set-redis-socketio-host redis:6379

    # Remove redis, watch from Procfile
    sed -i '/redis/d' ./Procfile
    sed -i '/watch/d' ./Procfile

    # Install LMS app
    bench get-app lms

    # Create and configure site
    bench new-site ${FRAPPE_SITE_NAME} \
    --force \
    --mariadb-root-password ${MYSQL_ROOT_PASSWORD} \
    --admin-password ${ADMIN_PASSWORD} \
    --no-mariadb-socket

    bench --site ${FRAPPE_SITE_NAME} install-app lms
    bench --site ${FRAPPE_SITE_NAME} clear-cache
    bench use ${FRAPPE_SITE_NAME}
fi

bench start
