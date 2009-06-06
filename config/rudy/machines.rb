
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
      size 'm1.small'              # 1 compute unit, 1.7GB, 150GB /mnt
      ami 'ami-e348af8a'           # Alestic Debian 5.0, 32-bit (US)
    end
    
    role :large do
      size 'm1.large'              # 4 compute units, 7.5GB, 840GB /mnt
      ami 'ami-fb57b092'           # Alestic Debian 5.0, 64-bit (US)
    end
    
    role :xlarge do
      size 'm1.xlarge'             # 8 compute units, 15GB, 1680GB /mnt
      ami 'ami-fb57b092'           # Alestic Debian 5.0, 64-bit (US)
    end
    
  end
end

