#!/usr/bin/env bash
set -euo pipefail

ZABBIX_VERSION=7.4

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "Error: must be run as root." >&2
    exit 1
fi


function install_on_ubuntu() {
    command -v wget >/dev/null 2>&1 || { apt-get update -y && apt-get install -y wget; }
    local version_id=$(cat /etc/os-release | grep '^VERSION_ID=' | awk -F '=' '{print $2}' | sed 's#"##g')

    PKG_FILE="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_${ZABBIX_VERSION}+ubuntu${version_id}_all.deb"
    PKG_TMP="$(mktemp --suffix=.deb)"
    
    wget -qO "$PKG_TMP" "$PKG_FILE"
    yes | dpkg -i "$PKG_TMP"
    
    rm -rf "$PKG_TMP"
    
    apt-get update -y
    apt-get install -y zabbix-agent2

    true;
}

function install_on_debian() {
    command -v wget >/dev/null 2>&1 || { apt-get update -y && apt-get install -y wget; }

    local version_id=$(cat /etc/os-release | grep '^VERSION_ID=' | awk -F '=' '{print $2}' | sed 's#"##g')

    PKG_FILE="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_${ZABBIX_VERSION}+debian${version_id}_all.deb"
    PKG_TMP="$(mktemp --suffix=.deb)"

    wget -qO "$PKG_TMP" "$PKG_FILE"
    yes | dpkg -i "$PKG_TMP"
    rm -rf "$PKG_TMP"

    apt-get update -y
    apt-get install -y zabbix-agent2 
    true;
}

function install_on_fedora() {
    command -v wget >/dev/null 2>&1 || { dnf update -y && dnf install -y wget; }

    EL=10

    PKG_FILE="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/rhel/10/noarch/zabbix-release-latest-${ZABBIX_VERSION}.el${EL}.noarch.rpm"

    rpm -Uvh --quiet "$PKG_FILE"

    dnf clean all -y
    dnf install -y zabbix-agent2
    true;
}


[ -r /etc/os-release ] || { echo "/etc/os-release not found" >&2; exit 1; }
LINUX_FLAVOR=$(cat /etc/os-release | grep '^ID=' | awk -F '=' '{print $2}')


case "${LINUX_FLAVOR,,}" in
    fedora)
      install_on_fedora
      ;;
    debian)
      install_on_debian
      ;;
    ubuntu)
      install_on_ubuntu
      ;;
    *)
      echo "Unknown distro '{$LINUX_FLAVOR}' - fedora/debian/ubuntu only"
      ;;
esac
