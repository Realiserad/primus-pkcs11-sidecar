#!/bin/bash

volume="/etc/primus"

if [ -d "/vault/secrets" ]; then
    for secret in /vault/secrets/*; do
        . "$secret"
        echo "🌱 Sourced environment variables from $secret"
    done
fi

echo "📀 Content on volume"
ls -lA "$volume"

if [ -f "$volume/configuration.json" ] && [ ! -f "$volume/primus.cfg" ]; then
    jinja2 "/root/primus.cfg.j2" "$volume/configuration.json" --format=json -o "$volume/primus.cfg"
    echo "🔨 Created primus.cfg"
    cat "$volume/primus.cfg"
    echo ""
fi

if [ ! -f "/usr/local/primus/etc/.secrets.cfg" ] && [ -f "$volume/.secrets.cfg" ]; then
    cp -p "$volume/.secrets.cfg" "/usr/local/primus/etc/"
    echo "🔑 Loaded secrets from volume"
elif [ ! -f "$volume/.secrets.cfg" ]; then
    echo "🔨 Onboarding client"
    if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASSWORD" ]; then
        echo "🔨 Configuring proxy"
        ppin -p -e "$PROXY_USER" "$PROXY_PASSWORD"
    fi
    if [ -n "$HSM_USER" ] && [ -n "$SETUP_PASSWORD" ] && [ -n "$PKCS11_PASSWORD" ]; then
        echo "🔨 Fetching permanent PIN for $HSM_USER"
        ppin -a -e "$HSM_USER" "$SETUP_PASSWORD" "$PKCS11_PASSWORD"
    fi
fi

if [ ! -f "/usr/local/primus/etc/.secrets.cfg" ]; then
    echo "🤔 Onboarding failed, wrong or expired credentials?"
else
    cp -p "/usr/local/primus/etc/.secrets.cfg" "$volume/"
    echo "📀 Stored secrets on volume"
fi

echo "😀 Starting PKCS#11 proxy for $(ppin -v)"
/opt/primekey/bin/start.sh