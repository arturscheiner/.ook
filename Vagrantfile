# kuberverse kubernetes cluster lab
# version: 0.5.0
# description: this Vagrantfile creates a cluster with masters and workers
# created by Artur Scheiner - artur.scheiner@gmail.com

require_relative 'conf.rb'
require_relative 'lab.rb'

Vagrant.configure("2") do |config|

  kvlab = KvLab.new()

    kvlab.createStorer(config)

    if MASTER_COUNT > 1
      kvlab.createScaler(config, "oo-SCALER_SH-oo")
    end

    kvlab.createMaster(config, "oo-MASTER_SH-oo", "oo-COMMON_SH-oo")
    kvlab.createWorker(config, "oo-WORKER_SH-oo", "oo-COMMON_SH-oo")

    config.vm.provision "shell",
     run: "always",
     inline: "swapoff -a; ip a | grep -E 'inet ' | awk '{print $2,$NF}' > ip_addr"
end
