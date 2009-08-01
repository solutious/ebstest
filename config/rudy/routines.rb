bonnie_dir = '/tmp/bonnie64'
 now = Time.now
 mon, day = now.mon.to_s.rjust(2, '0'), now.day.to_s.rjust(2, '0')
 hour, min = now.hour.to_s.rjust(2, '0'), now.min.to_s.rjust(2, '0')
bonnie_log = '/tmp/' << ['bonnie64', now.year, mon, day].join('-')
report_dir = './report/' << [now.year, mon, day].join('-')

## Update based on: http://orion.blog.heroku.com/past/2009/7/29/io_performance_on_ebs/

# ----------------------------------------------------------- COMMANDS --------
# The commands block defines shell commands that can be used in routines. The
# ones defined here are added to the default list defined by Rye::Cmd (Rudy 
# executes all SSH commands via Rye).
commands do
  allow :apt_get, 'apt-get', :y, :q          # Linux
  allow :pkg_install, 'pkg', 'install'       # Solaris
  allow :bonnie, "#{bonnie_dir}/Bonnie"
  allow :gtar
  allow :wget
end

# ----------------------------------------------------------- ROUTINES --------
# The routines block describes the repeatable processes for each machine group.
# To run a routine, specify its name on the command-line: rudy bonnie64
routines do
  
  benchmark do            # Run all EBS tests
    remote :root do
      date >> bonnie_log
      # The following commands are analogous to running:
      # $ bonnie -d /rudy/disk1 -m EBS-1GB -r -s 1000 >> bonnie_log
      bonnie(:d, '/rudy/disk1', :m, 'EBS-1GB',  :r, :s,  1000) >> bonnie_log
      bonnie(:d, '/mnt',        :m, 'MNT-1GB',  :r, :s,  1000) >> bonnie_log
      bonnie(:d, '/rudy/disk1', :m, 'EBS-5GB',  :r, :s,  5000) >> bonnie_log
      bonnie(:d, '/mnt',        :m, 'MNT-5GB',  :r, :s,  5000) >> bonnie_log
      bonnie(:d, '/rudy/disk1', :m, 'EBS-10GB', :r, :s, 10000) >> bonnie_log
      bonnie(:d, '/mnt',        :m, 'MNT-10GB', :r, :s, 10000) >> bonnie_log
      date >> bonnie_log
    end
    after :download_report
  end
  
  quick do                # A quick to make sure everything's working
    remote :root do
      date >> bonnie_log
      bonnie(:d, '/rudy/disk1', :m, 'EBS-0.1GB', :r, :s, 100)  >> bonnie_log
      bonnie(:d, '/mnt',        :m, 'MNT-0.1GB', :r, :s, 100)  >> bonnie_log
      date >> bonnie_log
    end
    after :download_report
  end
  
  download_report do
    remote :root do
      report_file = File.join([File.basename(bonnie_log), hostname].join('-'))
      file_download bonnie_log, report_file
    end
    local do
      mkdir :p, report_dir
      reports = ls.grep(/^bonnie/)
      mv reports, report_dir
      #git 'add', 'report'
      # I use quotes for the commit message because they're 
      # not added automatically when safe mode is disabled.
      #git 'commit', :m, "'Adding #{reports.join(', ')}'"
    end
  end
  

  installdeps do              # Install test software
    before :install_bonnie64
  end
  
  env :solaris do
    sysupdate do                # Prep system
      remote :root do
        #setenv('PATH', "/usr/local/bin:#{getenv['PATH']}")
        pkg_install :q, 'SUNWhea', 'SUNWarc'
        pkg_install :q, 'SUNWgnu-libiconv'
        pkg_install :q, 'SUNWgcc'
        pkg_install :q, 'SUNWruby18'
        #pkg_install :q, 'SUNWjruby'
      end
    end
    install_bonnie64 do         # Install Bonnie64 from source
      remote :root do
        wget :q, 'http://github.com/solutious/bonnie64/tarball/2004-09-01'
        gtar :z, :x, :f, 'solutious-bonnie64-82e740571a39a7ed9ce678034b19e637cafd596b.tar.gz'
        mv 'solutious-bonnie64-82e740571a39a7ed9ce678034b19e637cafd596b', bonnie_dir
        cd bonnie_dir
        setenv 'CC', '/usr/local/bin/gcc' 
        make 'SysV'     # SysV is required for Linux
      end
    end
    
    mount do 
      disks do
        create '/rudy/disk1'
      end
    end
    
    startup do
      disks do
        create '/rudy/disk1'
      end
      ## Format disk in Solaris http://developer.amazonwebservices.com/connect/message.jspa?messageID=127058
      after :sysupdate
      after :installdeps
    end
  end
  
  env :linux do
    sysupdate do                # Prep system
      remote :root do
        apt_get 'update'
        apt_get 'install', 'build-essential', 'git-core', 'subversion'
      end
    end
    install_bonnie64 do         # Install Bonnie64 from source
      remote :root do
        wget :q, 'http://github.com/solutious/bonnie64/tarball/2004-09-01'
        tar :z, :x, :f, 'solutious-bonnie64-82e740571a39a7ed9ce678034b19e637cafd596b.tar.gz'
        mv 'solutious-bonnie64-82e740571a39a7ed9ce678034b19e637cafd596b', bonnie_dir
        cd bonnie_dir
        make 'SysV'     # SysV is required for Linux
      end
    end
    startup do
      disks do
        create '/rudy/disk1'
      end
      after :sysupdate
      after :installdeps
    end
  end
  
  
  shutdown do
    disks do
      destroy '/rudy/disk1'
    end
  end
  
end
