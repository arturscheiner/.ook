# kuberverse kubernetes cluster lab
# version: 0.5.0
# description: this Vagrantfile creates a cluster with masters and workers
# created by Artur Scheiner - artur.scheiner@gmail.com

# Is not recommended, but you can change the base box.
# This means that all the VMs will use the same image.
# For vmware_desktop provider use
# BOX_IMAGE = "bento/ubuntu-18.04"
# For virtualbox provider you can choose to use
# bento or kuberverse images. The difference is
# that kuberverse images are pre-loaded with
# the packages needed to create the cluster
# that means less time to build the cluster.
#BOX_IMAGE = "kuberverse/gubuntu-18.04.01"
BOX_K8S_IMAGE = "kuberverse/ubuntu-18.04"
BOX_XTR_IMAGE = "generic/alpine315"

# Choose the vm.provider.
# Kuberverse supports virtualbox | libvirt
VM_PROVIDER = "libvirt"

# Define the k8s version to be used on this lab.
KUBE_VERSION = "1.22.3"

# Define the container runtime that will be used on
# your lab. From k8s v1.22 the default runtime is containerd.
# You can choose between containerd|docker
CONTAINER_RUNTIME = "containerd"

# Define CNI Provider
# Choose between calico|weave|flannel
CNI_PROVIDER = "weave"

# Change these values if you wish to play with the 
# cluster size. Do this before starting your cluster
# provisioning.
MASTER_COUNT = 1
WORKER_COUNT = 1

# Change these values if you wish to play with the 
# VMs memory resources.
# Kubernetes pre-flight for the MASTER_NODES now requires 1700+ of memory.
SCALER_MEMORY = 512
STORER_MEMORY = 256
MASTER_MEMORY = 2048
WORKER_MEMORY = 1024

STORER_VCPUS = 1
SCALER_VCPUS = 1
MASTER_VCPUS = 2
WORKER_VCPUS = 2

STORER_NAME = "kv-storer"
SCALER_NAME = "kv-scaler"
MASTER_NAME = "kv-master"
WORKER_NAME = "kv-worker"

# Change these values if you wish to play with the
# networking settings of your cluster 
KV_LAB_NETWORK = "10.8.8.0"

# This value changes the intra-pod network
POD_CIDR = "172.18.0.0/16"


KVMSG = "Kuberverse Kubernetes Cluster Lab"
