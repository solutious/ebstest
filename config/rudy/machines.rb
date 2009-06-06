
# ---------------------------------------------------------  MACHINES  --------
# The machines block describes the "physical" characteristics of your machines.
machines do
  env :linux do
    
    disks do                       # Define EBS volumes 
      path '/rudy/disk1' do        # The paths can be anything but
        size 50                    # they must be unique. 
        device '/dev/sdr'          # Devices must be unique too.
      end
    end
    
    role :small do
      size 'm1.small'              # EC2 machine type for all machines      
      ami 'ami-e348af8a'           # Alestic Debian 5.0, 32-bit (US)
    end
    
    role :large do
      size 'm1.large'
      ami 'ami-fb57b092'           # Alestic Debian 5.0, 64-bit (US)
    end
    
  end
end

