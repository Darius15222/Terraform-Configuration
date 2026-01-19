#!/bin/sh
# Best-effort pfSense bootstrap. This AMI may ignore user_data.
set -eu

if [ -x /usr/local/sbin/pfSsh.php ]; then
  cat > /tmp/userdata-config.php <<'PHP'
<?php
require_once("config.inc");
global $config;
$config["system"]["hostname"] = "pfsense";
$config["system"]["domain"] = "lab.local";
write_config("Bootstrap hostname/domain from user_data");
?>
PHP
  /usr/local/sbin/pfSsh.php < /tmp/userdata-config.php
fi
