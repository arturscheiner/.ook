#!/usr/bin/env bash
# kuberverse kubernetes cluster lab
# version: 0.5.0
# description: this is the workers script file
# created by Artur Scheiner - artur.scheiner@gmail.com

#$(cat $KV_DIR/workers-join | sed -e 's/^[ \t]*//' | tr '\n' ' ' | sed -e 's/ \\ / /g')
cat $KV_DIR/workers-join | bash

if grep -E "KUBELET_EXTRA_ARGS=" /etc/default/kubelet ; then
  sed -i "s+KUBELET_EXTRA_ARGS=\"+KUBELET_EXTRA_ARGS=\"--node-ip=$KV_THIS_IP +g" /etc/default/kubelet
else
  echo KUBELET_EXTRA_ARGS=--node-ip=$KV_THIS_IP  >> /etc/default/kubelet
fi

while [ ! -f $KV_DIR/kube-config ]; do sleep 2; done

mkdir -p /home/vagrant/.kube /root/.kube
\cp -r $KV_DIR/kube-config /home/vagrant/.kube/config
\cp -r $KV_DIR/kube-config /root/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

systemctl restart kubelet
