# Cody Herriges <cody@puppetlabs.com>
#
# Collects and creates a fact for every package installed on the system and
# returns that package's version as the fact value.  Useful for doing package
# inventory and making decisions based on installed package versions.
module Facter::Util::Pkg
  def self.validname(name)
    name
      .tr('-+.','_') # RPM and deb packages might contain these
      .sub(/:.*/,'') # Debian multiarch arch qualifiers
  end

  def self.package_list
    packages = []
    case Facter.operatingsystem
    when 'Debian', 'Ubuntu'
      command = 'dpkg-query -W'
      packages = []
      Facter::Util::Resolution.exec(command).each_line do |pkg|
        name,version = pkg.chomp.split("\t")
        packages << [Facter::Util::Pkg::validname(name),version]
      end
    when 'CentOS', 'RedHat', 'Fedora'
      command = 'rpm -qa --qf %{NAME}"\t"%{VERSION}-%{RELEASE}"\n"'
      packages = []
      Facter::Util::Resolution.exec(command).each_line do |pkg|
        name,version = pkg.chomp.split("\t")
        packages << [Facter::Util::Pkg::validname(name),version]
      end
    when 'Solaris'
      command = 'pkginfo -x'
      combined = ''
      packages = []
      Facter::Util::Resolution.exec(command).each_line do |line|
        if line =~ /^\w/
          then
            combined << line.chomp
          else
            combined << line
        end
      end
      combined.each_line do |pkg|
        packages << pkg.chomp.scan(/^(\S+).*\s(\d.*)/)[0]
      end
    end
    return packages
  end
end
