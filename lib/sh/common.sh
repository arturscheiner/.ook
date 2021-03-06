#!/usr/bin/env bash
# kuberverse kubernetes cluster lab
# version: 0.5.0
# description: this is a common script file for masters and workers
# created by Artur Scheiner - artur.scheiner@gmail.com

#variable definitions

if [[ ! $KV_BOX_K8S_IMAGE =~ "kuberverse" ]]
then

  UBUNTU_CODENAME=$(lsb_release -cs)

  export DEBIAN_FRONTEND=noninteractive

  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common apt-cacher-ng

  sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
  
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable"

  add-apt-repository -y ppa:projectatomic/ppa

  apt-get update

  apt-get install -y containerd docker.io software-properties-common podman containers-common \
                    traceroute htop httpie bash-completion ruby \
                    kubelet=${KV_KUBE_VERSION}-00 kubeadm=${KV_KUBE_VERSION}-00 kubectl=${KV_KUBE_VERSION}-00 kubernetes-cni
  
  sed -i "s+# PassThroughPattern: \.\*+PassThroughPattern: .*+g" /etc/apt-cacher-ng/acng.conf
  systemctl restart apt-cacher-ng
  systemctl start apt-cacher-ng
  systemctl enable apt-cacher-ng
  echo 'Acquire::http::Proxy "http://10.8.8.10:3142";' >> /etc/apt/apt.conf.d/00aptproxy
  echo -e 'Dpkg::Progress-Fancy "1";\nAPT::Color "1";' >> /etc/apt/apt.conf.d/99progress
fi

case $KV_CONTAINER_RUNTIME in
containerd)

### containerd

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system
mkdir -p /etc/containerd


### containerd config
cat > /etc/containerd/config.toml <<EOF
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[plugins]

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      base_runtime_spec = ""
      container_annotations = []
      pod_annotations = []
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        BinaryName = ""
        CriuImagePath = ""
        CriuPath = ""
        CriuWorkPath = ""
        IoGid = 0
        IoUid = 0
        NoNewKeyring = false
        NoPivotRoot = false
        Root = ""
        ShimCgroup = ""
        SystemdCgroup = true
EOF


### crictl uses containerd as default
{
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF
}


### kubelet should use containerd x
{
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime remote --container-runtime-endpoint unix:///run/containerd/containerd.sock"
EOF
}


### install podman
cat <<EOF | sudo tee /etc/containers/registries.conf
[registries.search]
registries = ['docker.io']
EOF

if [[ $(podman network ls | grep podman) ]]; then podman network rm podman; fi

### start services
systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd
systemctl enable kubelet && systemctl start kubelet
;;
docker)

# Setup Docker daemon
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker
systemctl daemon-reload
systemctl restart docker

;;
cri-o)
#not supported yet
;;
*)
#no default defined
;;
esac

if [[ ! $KV_BOX_K8S_IMAGE =~ "kuberverse" ]]
then
  kubeadm config images pull
fi
