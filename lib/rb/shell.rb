# kuberverse kubernetes cluster lab
# version: 0.5.0
# description: this Vagrantfile creates a cluster with masters and workers
# created by Artur Scheiner - artur.scheiner@gmail.com

class KvShell
    def env(node,ip,hostname,sIPs,mIPs,wIPs)
        <<-SCRIPT
        export KV_KVMSG='#{KVMSG}'
        export KV_BOX_K8S_IMAGE=#{BOX_K8S_IMAGE}
        export KV_BOX_XTR_IMAGE=#{BOX_XTR_IMAGE}
        export KV_KUBE_VERSION=#{KUBE_VERSION}
        export KV_CONTAINER_RUNTIME=#{CONTAINER_RUNTIME}
        export KV_CNI_PROVIDER=#{CNI_PROVIDER}
        export KV_MASTER_COUNT=#{MASTER_COUNT}
        export KV_WORKER_COUNT=#{WORKER_COUNT}
        export KV_POD_CIDR=#{POD_CIDR}  
        export KV_MASTER_TYPE=#{MASTER_COUNT == 1 ? "single" : "multi"}
        export KV_THIS_IP=#{ip}
        export KV_THIS_NODE=#{node}
        export KV_THIS_HOSTNAME=#{hostname}
        export KV_SCALER_IPS_ARRAY="#{sIPs}"
        export KV_MASTER_IPS_ARRAY="#{mIPs}"
        export KV_WORKER_IPS_ARRAY="#{wIPs}"
        export KV_LAB_NETWORK="#{KV_LAB_NETWORK}"
        export KV_SCALER_NAME="#{SCALER_NAME}"
        export KV_MASTER_NAME="#{MASTER_NAME}"
        export KV_STORER_NAME="#{STORER_NAME}"
        export KV_DIR="/mnt/.ook"
        export KV_STORER_SH="$KV_DIR/sh/storer.sh"
        export KV_SCALER_SH="$KV_DIR/sh/scaler.sh"
        export KV_COMMON_SH="$KV_DIR/sh/common.sh"
        export KV_WORKER_SH="$KV_DIR/sh/worker.sh"
        export KV_MASTER_SH="$KV_DIR/sh/master.sh"
        export KV_STORAGE="$KV_STORER_NAME-0"
        printenv | grep -E '^KV_' | sed 's/^/export /' >> ~/.bash_profile
        ip a | grep -E 'inet ' | awk '{print $2,$NF}' > ip_addr
        cat /vagrant/hosts >> /etc/hosts
        mkdir -p $KV_DIR/sh
        SCRIPT
    end
    
    def storer()
        <<-SCRIPT
        touch $KV_DIR/$HOSTNAME.run
        chown -R nobody:nogroup $KV_DIR/
        apk add nfs-utils
        rc-update add nfs
    
        echo "$KV_DIR $KV_LAB_NETWORK/24(rw,sync,no_subtree_check)" >> /etc/exports
        #cp /vagrant/lib/sh/* $KV_DIR/sh/
        chmod +x $KV_DIR/sh/*
        
        sed -i 's/-HUP/-s HUP/g' /etc/init.d/nfs
        service nfs start
        rm $KV_DIR/$HOSTNAME.run
        SCRIPT
    end

    def scaler(script)
        <<-SCRIPT
        apk add nfs-utils
        rc-update add nfsmount
        rc-service nfsmount start
        while [ ! $(mount | grep $KV_DIR) ]; do sleep 2; mount -t nfs $KV_STORAGE:$KV_DIR $KV_DIR; done
        touch $KV_DIR/$HOSTNAME.run
        #while [ ! -f $KV_SCALER_SH ]; do sleep 2; done
        #/bin/bash -c "$KV_SCALER_SH"
        echo '#{script}' | base64 -d | bash
        rm $KV_DIR/$HOSTNAME.run
        SCRIPT
    end
    
    def worker(script,common)
        <<-SCRIPT       
        apt-get install -y nfs-common
        while [ ! $(mount | grep $KV_DIR) ]; do sleep 2; mount $KV_STORAGE:$KV_DIR $KV_DIR; done
        touch $KV_DIR/$HOSTNAME.run

        ##while [ ! -f $KV_COMMON_SH ]; do sleep 2; done
        #/bin/bash -c "$KV_COMMON_SH"   
        echo '#{common}' | base64 -d | bash

        while [ ! -f $KV_DIR/workers-join ]; do sleep 2; done
        #/bin/bash -c "$KV_WORKER_SH"
        echo '#{script}' | base64 -d | bash

        while [ ! "$(kubectl get nodes | grep $HOSTNAME)" ]; do printf "%b" "\x1B[31mNode $HOSTNAME not connected to the cluster!\e[0m\r\n"; sleep 1; done
        printf "%b" "\x1B[32mNode $HOSTNAME connected to the cluster successfully!\e[0m\r\n"
        rm $KV_DIR/$HOSTNAME.run
        SCRIPT
    end

    def master(script,common)
        <<-SCRIPT     
        apt-get install -y nfs-common
        while [ ! $(mount | grep $KV_DIR) ]; do sleep 2; mount $KV_STORAGE:$KV_DIR $KV_DIR; done
        touch $KV_DIR/$HOSTNAME.run

        #while [ ! -f $KV_COMMON_SH ]; do sleep 2; done
        #/bin/bash -c "$KV_COMMON_SH"
        echo '#{common}' | base64 -d | bash
        

        if (( $KV_MASTER_COUNT > 1 && $KV_THIS_NODE > 0 )); then 
            while [ ! -f $KV_DIR/masters-join-default ]; do sleep 2; done
        fi

        #while [ ! -f $KV_MASTER_SH ]; do sleep 2; done
        #/bin/bash -c "$KV_MASTER_SH"
        echo '#{script}' | base64 -d | bash

        while [ ! "$(kubectl get nodes | grep $HOSTNAME)" ]; do printf "%b" "\x1B[31mNode $HOSTNAME not connected to the cluster!\e[0m\r\n"; sleep 1; done
        printf "%b" "\x1B[32mNode $HOSTNAME connected to the cluster successfully!\e[0m\r\n"
        rm $KV_DIR/$HOSTNAME.run
        SCRIPT
    end

end
