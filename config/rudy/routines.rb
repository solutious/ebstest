bonnie_dir = '/tmp/bonnie-64-read-only'
 now = Time.now
 mon, day = now.mon.to_s.rjust(2, '0'), now.day.to_s.rjust(2, '0')
 hour, min = now.hour.to_s.rjust(2, '0'), now.min.to_s.rjust(2, '0')
bonnie_log = '/tmp/' << ['bonnie64', now.year, mon, day].join('-')
report_dir = './report/' << [now.year, mon, day].join('-')

# ----------------------------------------------------------- COMMANDS --------
# The commands block defines shell commands that can be used in routines. The
# ones defined here are added to the default list defined by Rye::Cmd (Rudy 
# executes all SSH commands via Rye).
commands do
  allow :apt_get, 'apt-get', :y, :q
  allow :gem_install, '/usr/bin/gem', 'install', :n, '/usr/bin', :y, :V, '--no-rdoc', '--no-ri'
  allow :gem_sources, '/usr/bin/gem', 'sources'
  allow :update_rubygems
  allow :bonnie, "#{bonnie_dir}/Bonnie"
end

# ----------------------------------------------------------- ROUTINES --------
# The routines block describes the repeatable processes for each machine group.
# To run a routine, specify its name on the command-line: rudy bonnie64
routines do
  
  benchmark do            # Run all EBS tests
    script :root do
      date >> bonnie_log
      # The following commands are analogous to running:
      # $ bonnie -d /rudy/disk -m EBS-1GB -r -s 1000 > bonnie_log
      bonnie(:d, '/rudy/disk1', :m, 'EBS-1GB',  :r, :s,  1000) >> bonnie_log
      bonnie(:d, '/mnt',        :m, 'MNT-1GB',  :r, :s,  1000) >> bonnie_log
      bonnie(:d, '/rudy/disk1', :m, 'EBS-5GB',  :r, :s,  5000) >> bonnie_log
      bonnie(:d, '/mnt',        :m, 'MNT-5GB',  :r, :s,  5000) >> bonnie_log
      bonnie(:d, '/rudy/disk1', :m, 'EBS-10GB', :r, :s, 10000) >> bonnie_log
      bonnie(:d, '/mnt',        :m, 'MNT-10GB', :r, :s, 10000) >> bonnie_log
      bonnie(:d, '/rudy/disk1', :m, 'EBS-25GB', :r, :s, 25000) >> bonnie_log
      bonnie(:d, '/mnt',        :m, 'MNT-25GB', :r, :s, 25000) >> bonnie_log
      date >> bonnie_log
    end
    after :download_report
  end
  
  quick do                # A quick to make sure everything's working
    script :root do
      date >> bonnie_log
      bonnie(:d, '/rudy/disk1', :m, 'EBS-0.1GB', :r, :s, 100)  >> bonnie_log
      bonnie(:d, '/mnt',        :m, 'MNT-0.1GB', :r, :s, 100)  >> bonnie_log
      date >> bonnie_log
    end
    after :download_report
  end
  
  download_report do
    script :root do
      report_file = File.join([File.basename(bonnie_log), hostname].join('-'))
      download bonnie_log, report_file
    end
    after_local do
      disable_safe_mode
      mkdir :p, report_dir
      reports = ls 'bonnie64*'
      mv reports, report_dir
      git 'add', 'report'
      # I use quotes for the commit message because they're 
      # not added automatically when safe mode is disabled.
      git 'commit', :m, "'Adding #{reports.join(', ')}'"
    end
  end
  
  
  sysupdate do                # Prep system
    script :root do
      apt_get 'update'
      apt_get 'install', 'build-essential', 'git-core', 'subversion'
      apt_get 'install', 'ruby1.8-dev', 'rubygems'
      gem_sources :a, 'http://gems.github.com'
      gem_install 'rubygems-update'
      update_rubygems
    end
  end

  installdeps do              # Install test software
    script :root do
    end
    after :install_bonnie64
  end
  
  install_bonnie64 do         # Install Bonnie64 from source
    script :root do
      svn 'checkout', 'http://bonnie-64.googlecode.com/svn/trunk/', bonnie_dir
      cd bonnie_dir
      make 'SysV' # SysV is required for Linux (and probably Solaris)
    end
  end
  
  startup do
    disks do
      create '/rudy/disk1'
    end
    after :sysupdate
    after :installdeps
  end
  
  shutdown do
    disks do
      destroy '/rudy/disk1'
    end
  end
  
end
