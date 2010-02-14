server "ec2-184-73-9-120.compute-1.amazonaws.com", :app, :web, :db, :primary => true

ssh_options[:keys] = ["#{ENV['HOME']}/.sumo/keypair.pem"]
