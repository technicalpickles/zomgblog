server "ec2-75-101-251-207.compute-1.amazonaws.com", :app, :web, :db, :primary => true

ssh_options[:keys] = ["#{ENV['HOME']}/.sumo/keypair.pem"]
