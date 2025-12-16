#!/bin/bash

# 1. Fix the shebang (added missing /)

# Check if bench already exists
if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping init..."
    cd frappe-bench

else
    echo "Creating new bench..."
    
    # 2. ALL setup commands must be inside this block
    # otherwise they run every time and overwrite your data!
    
    # Make sure we are in the right node environment (optional, usually handled by image)
    export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION_DEVELOP}/bin/:${PATH}"

    bench init --skip-redis-config-generation frappe-bench
    
    cd frappe-bench

    # Use containers instead of localhost
    bench set-mariadb-host mariadb
    bench set-redis-cache-host redis://redis:6379
    bench set-redis-queue-host redis://redis:6379
    bench set-redis-socketio-host redis://redis:6379

    # Remove redis, watch from Procfile (since we use Docker for these)
    sed -i '/redis/d' ./Procfile
    sed -i '/watch/d' ./Procfile

    # Install your app
    bench get-app lms

    # Create the site matching your REAL domain
    # (Used lms.growthcomarketing.com instead of localhost so Traefik routing works perfectly)
    bench new-site lms.growthcomarketing.com \
    --force \
    --mariadb-root-password 123 \
    --admin-password admin \
    --no-mariadb-socket

    bench --site lms.growthcomarketing.com install-app lms
    bench --site lms.growthcomarketing.com set-config developer_mode 1
    bench --site lms.growthcomarketing.com clear-cache
    bench use lms.growthcomarketing.com
fi

# 3. Always run this at the very end, regardless of the path taken
echo "Starting Bench..."
bench start
