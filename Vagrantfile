# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"

  config.vm.define "seleniumhub" do |senodehub|
    # 202 = 0xCA. Easy, eh?
    senodehub.vm.network "private_network", :ip => "172.16.202.120"

    # Install Librarian-puppet first
    senodehub.vm.provision :shell, :path => "shell/main.sh"

    # Run puppet
    senodehub.vm.provision :puppet do |puppet|
      puppet.manifests_path = "manifests"
      puppet.manifest_file = "sehub.pp"
      puppet.options = "--verbose --debug"
    end

    # Restart Selenium
    senodehub.vm.provision "shell",
      inline: "sudo service senode stop; sudo service sehub stop; sudo pkill java; sudo pkill phantomjs; sudo /etc/init.d/sehub start && sleep 3 && sudo /etc/init.d/senode start"
  end
end
