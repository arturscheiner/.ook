# kuberverse kubernetes cluster lab
# version: 0.5.0
# description: this Vagrantfile creates a cluster with masters and workers
# created by Artur Scheiner - artur.scheiner@gmail.com

require_relative 'kvshell.rb'
require_relative 'kvtools.rb'

class KvLab

    def initialize
        @kvshell = KvShell.new()
        @kvtools = KvTools.new()


        if MASTER_COUNT >= 2
          $sIPs = @kvtools.iPSa("scaler",1)
        else
          $sIPs = []
        end

        $mIPs = @kvtools.iPSa("master",MASTER_COUNT)
        $wIPs = @kvtools.iPSa("worker",WORKER_COUNT)

        #puts "********** #{KVMSG.green}**********"
  
        #checkmark = "\u2713"
        #puts checkmark.force_encoding('utf-8').green.bold.blink
  
        #puts "---- Provisioned with k8s #{KUBE_VERSION.yellow}".blue
        #puts "---- Container runtime is: #{CONTAINER_RUNTIME.yellow}"
        #puts "---- CNI Provider is: #{CNI_PROVIDER.yellow}"
        #puts "---- #{MASTER_COUNT} Masters Nodes"
        #puts "---- #{WORKER_COUNT} Worker(s) Node(s)" unless MASTER_COUNT == 5
    end

    def createScaler(config,script)
  
      node = 0
      ip = @kvtools.defineIp("scaler",node,KV_LAB_NETWORK)
  
        if MASTER_COUNT != 1
          #puts "---- 1 Scaler Node"
          #puts "The Scaler #{node} Ip is #{ip}"
        end
        config.vm.synced_folder ".", "/vagrant"
        config.vm.define "#{SCALER_NAME}-#{node}" do |scaler|    
          scaler.vm.box = BOX_XTR_IMAGE
          scaler.vm.provider VM_PROVIDER
          scaler.vm.hostname = "#{SCALER_NAME}-#{node}"
          scaler.vm.network :private_network, ip: ip, nic_type: "virtio"
          scaler.vm.network "forwarded_port", guest: 6443, host: 6443
          
          scaler.vm.provider :libvirt do |lv|
            lv.cpus = SCALER_VCPUS
            lv.memory = SCALER_MEMORY
            lv.disk_bus = "virtio"
            lv.driver = "kvm"
            lv.video_vram = 256
            lv.forward_ssh_port = true
          end 

          scaler.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--cpus", 2, "--nictype1", "virtio"]
            vb.memory = SCALER_MEMORY
          end
  
          if !BOX_K8S_IMAGE.include? "kuberverse"
            scaler.vm.provider "vmware_desktop" do |v|
              v.vmx["memsize"] = SCALER_MEMORY
              v.vmx["numvcpus"] = "2"
            end
          end
          if ARGV[0] == "destroy"
            #puts "Deleting .kv directory"
            @kvtools.cleanKvDir()     
          else
            @kvtools.addToHosts(ip,scaler.vm.hostname)
          end
          $s_script = @kvshell.env(node,ip,scaler.vm.hostname,$sIPs,$mIPs,$wIPs) + @kvshell.scaler(script)
          scaler.vm.provision "shell", inline: $s_script, keep_color: true
        end
    end

    def createStorer(config)
  
      node = 0
      ip = @kvtools.defineIp("storer",node,KV_LAB_NETWORK)
  
        #puts "---- 1 Storer Node"
        #puts "The Storer #{node} Ip is #{ip}"
        config.vm.synced_folder ".", "/vagrant"
        config.vm.define "#{STORER_NAME}-#{node}" do |storer|    
          storer.vm.box = BOX_XTR_IMAGE
          storer.vm.provider VM_PROVIDER
          storer.vm.hostname = "#{STORER_NAME}-#{node}"
          storer.vm.network :private_network, ip: ip, nic_type: "virtio"
          storer.vm.network "forwarded_port", guest: 6443, host: 6443
          
          storer.vm.provider :libvirt do |lv|
            lv.cpus = STORER_VCPUS
            lv.memory = STORER_MEMORY
            lv.disk_bus = "virtio"
            lv.driver = "kvm"
            lv.video_vram = 256
            lv.forward_ssh_port = true
          end 

          storer.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--cpus", 2, "--nictype1", "virtio"]
            vb.memory = STORER_MEMORY
          end
  
          if !BOX_K8S_IMAGE.include? "kuberverse"
            storer.vm.provider "vmware_desktop" do |v|
              v.vmx["memsize"] = STORER_MEMORY
              v.vmx["numvcpus"] = "2"
            end
          end
          if ARGV[0] == "destroy"
            puts "Deleting .kv directory"
            @kvtools.cleanKvDir()     
          else
            @kvtools.addToHosts(ip,storer.vm.hostname)
          end
          $s_script = @kvshell.env(node,ip,storer.vm.hostname,$sIPs,$mIPs,$wIPs) + @kvshell.storer()
          storer.vm.provision "shell", inline: $s_script, keep_color: true
        end
    end
    
    def createMaster(config,script,common)
     
      (0..MASTER_COUNT-1).each do |node|
        ip = @kvtools.defineIp("master",node,KV_LAB_NETWORK)
  
        #puts "The Master #{node} Ip is #{ip}"

        config.vm.synced_folder ".", "/vagrant"
        config.vm.define "#{MASTER_NAME}-#{node}" do |master|
          master.vm.box = BOX_K8S_IMAGE
          master.vm.provider VM_PROVIDER
          master.vm.hostname = "#{MASTER_NAME}-#{node}"
          master.vm.network :private_network, ip: ip, nic_type: "virtio"      
  
          if MASTER_COUNT == 1
            master.vm.network "forwarded_port", guest: 6443, host: 6443
            server = master.vm.hostname
          end
          
          master.vm.provider :libvirt do |lv|
            lv.cpus = MASTER_VCPUS
            lv.memory = MASTER_MEMORY
            lv.disk_bus = "virtio"
            lv.forward_ssh_port = true
          end 

          master.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--cpus", 2, "--nictype1", "virtio"]
            vb.memory = MASTER_MEMORY
          end
  
          if !BOX_K8S_IMAGE.include? "kuberverse"
            master.vm.provider "vmware_desktop" do |v|
              v.vmx["memsize"] = MASTER_MEMORY
              v.vmx["numvcpus"] = "2"
            end
          end
          if ARGV[0] == "destroy"
            #puts "Deleting .kv directory"
            @kvtools.cleanKvDir()     
          else
            @kvtools.addToHosts(ip,master.vm.hostname)
          end
          @kvtools.addToFile("masters",master.vm.hostname)
          $m_script = @kvshell.env(node,ip,master.vm.hostname,$sIPs,$mIPs,$wIPs) + @kvshell.master(script,common)

          master.vm.provision "shell", inline: $m_script, keep_color: true
        end
      end   
    end
  
    def createWorker(config,script,common)
      (0..WORKER_COUNT-1).each do |node|
        ip = @kvtools.defineIp("worker",node,KV_LAB_NETWORK)
  
        #puts "The Worker #{node} Ip is #{ip}"

        config.vm.synced_folder ".", "/vagrant"  
        config.vm.define "#{WORKER_NAME}-#{node}" do |worker|
          worker.vm.box = BOX_K8S_IMAGE
          worker.vm.provider VM_PROVIDER
          worker.vm.hostname = "#{WORKER_NAME}-#{node}"
          worker.vm.network :private_network, ip: ip, nic_type: "virtio"
          worker.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--cpus", 2, "--nictype1", "virtio"]
            vb.memory = WORKER_MEMORY
          end

          worker.vm.provider :libvirt do |lv|
            lv.cpus = WORKER_VCPUS
            lv.memory = WORKER_MEMORY
            lv.disk_bus = "virtio"
            lv.forward_ssh_port = true
          end 

          if !BOX_K8S_IMAGE.include? "kuberverse"
            worker.vm.provider "vmware_desktop" do |v|
              v.vmx["memsize"] = WORKER_MEMORY
              v.vmx["numvcpus"] = "2"
            end
          end
          if ARGV[0] == "destroy"
            #puts "Deleting .kv directory"
            @kvtools.cleanKvDir()     
          else
            @kvtools.addToHosts(ip,worker.vm.hostname)
          end
          @kvtools.addToFile("workers",worker.vm.hostname)
          $w_script = @kvshell.env(node,ip,worker.vm.hostname,$sIPs,$mIPs,$wIPs) + @kvshell.worker(script,common)
          worker.vm.provision "shell", inline: $w_script, keep_color: true
        end
      end
    end
    
  end
