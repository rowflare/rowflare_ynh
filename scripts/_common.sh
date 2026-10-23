#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# Build the web app and the Worker bundle, then drop the build-only dependencies.
# pnpm is the version pinned in package.json ("packageManager"), fetched by corepack.
# Caches go to $install_dir/.cache so they can be removed afterwards.
_rowflare_build() {
    # XDG_DATA_HOME holds the pnpm store, which install and prune must share
    local cache="$install_dir/.cache"
    local env_vars=(XDG_CACHE_HOME="$cache" XDG_CONFIG_HOME="$cache/config" XDG_DATA_HOME="$cache/data" NPM_CONFIG_CACHE="$cache/npm" CI=true WRANGLER_SEND_METRICS=false)
    pushd "$install_dir" || return 1
        ynh_hide_warnings ynh_exec_as_app "${env_vars[@]}" corepack pnpm install --frozen-lockfile
        ynh_hide_warnings ynh_exec_as_app "${env_vars[@]}" corepack pnpm run build:docker
        ynh_hide_warnings ynh_exec_as_app "${env_vars[@]}" corepack pnpm prune --prod
    popd || return 1
    ynh_safe_rm "$cache"
    ynh_safe_rm "$install_dir/.wrangler"
}

# Create the owner account through the sign-up API. On a fresh instance the first account becomes the owner,
# so this is done during install instead of leaving the instance open for whoever opens it first.
# The x-rf header is Rowflare's CSRF guard for sign-in requests.
_rowflare_create_owner() {
    local email
    email=$(ynh_user_get_info --username="$admin" --key=mail)
    local payload
    payload=$(EMAIL="$email" PASSWORD="$password" NAME="$admin" \
        node -e 'process.stdout.write(JSON.stringify({ email: process.env.EMAIL, password: process.env.PASSWORD, name: process.env.NAME }))')
    local http_code
    http_code=$(curl --silent --output /dev/null --write-out "%{http_code}" \
        --header "Content-Type: application/json" --header "x-rf: 1" --data-binary @- \
        "http://127.0.0.1:$port/api/auth/signup" <<< "$payload")
    if [ "$http_code" != "200" ]; then
        ynh_die "Could not create the Rowflare owner account (HTTP $http_code). The password must be at least 8 characters."
    fi
}
