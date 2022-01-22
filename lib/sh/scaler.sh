#!/usr/bin/env bash
# kuberverse kubernetes cluster lab
# version: 0.5.0
# description: this is the scaler (load balancer) script file
# created by Artur Scheiner - artur.scheiner@gmail.com

MASTER_IPS=$(echo $KV_MASTER_IPS_ARRAY | sed -e 's/,//g' -e 's/\]//g' -e 's/\[//g')

apk add rsyslog haproxy

rc-update add rsyslog boot
rc-update add haproxy boot

tee /etc/rsyslod.d/haproxy <<EOF
# Collect log with UDP
$ModLoad imudp
$UDPServerAddress 127.0.0.1
$UDPServerRun 514

# Creating separate log files based on the severity
local0.* /var/log/haproxy-traffic.log
local0.notice /var/log/haproxy-admin.log
EOF

tee /etc/haproxy/haproxy.cfg <<EOF
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log         127.0.0.1:514 local0

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats
#        ca-base /etc/ssl/certs
#        crt-base /etc/ssl/private

#        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    tcp
    log                     global
    option                  tcplog
    option                  dontlognull
    retries                 3
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout check           10s

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    tcp
    log                     global
    option                  tcplog
    option                  dontlognull
    retries                 3
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout check           10s

#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend entrypoint
    bind *:6443
    mode tcp
    default_backend             masters

#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend masters
    balance     roundrobin
    option	log-health-checks
#    server  kv-master-0 10.8.8.10:6443 check
#    server  kv-master-1 10.8.8.10:6443 check
    

#frontend $KV_SCALER_NAME
#        bind *:6443
#        mode tcp
#        log global
#        option tcplog
#        timeout client 3600s
#        backlog 4096
#        maxconn 50000
#        use_backend kv-masters

#backend kv-masters
#        mode  tcp
#        option log-health-checks
#        option redispatch
#        option tcplog
#        balance roundrobin
#        timeout connect 1s
#        timeout queue 5s
#        timeout server 3600s
EOF

i=0
for mips in $MASTER_IPS; do
  echo "    server $KV_MASTER_NAME-$i $mips:6443 check" >> /etc/haproxy/haproxy.cfg
  ((i++))
done

cat /vagrant/.kv/hosts >> /etc/hosts

service rsyslog start
service haproxy start