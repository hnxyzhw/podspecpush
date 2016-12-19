require "podspecpush/version"
require 'trollop'

module Podspecpush
  class PodPush
    def push
      opts = Trollop::options do
        opt :repo, "Repo name", :type => :string
        opt :force, "Pod verify & push with warnings"
      end
      Trollop::die :repo, "Repo must be provided" if opts[:repo] == nil

      force = opts[:force]
      repoName = opts[:repo]

      podspecName = `ls | grep .podspec`.strip

      clean = `git status --porcelain`

      if clean.length != 0 
        puts "Repo is not clean; will not push new version"
        exit
      end

      version = `git describe --abbrev=0`.strip

      newFile = ""

      File.readlines(podspecName).each do |line|
        idx = /  s.version/ =~ line
        if idx != nil && idx >= 0 
          startIdx = line.index("\'")
          endIdx = line.index("\'", startIdx + 1)
          currentVersion = line[startIdx + 1...endIdx]
          if currentVersion == version
            puts "Can't push same version silly!"
            exit
          end
          line[startIdx +1 ...endIdx] = version
        end
  
        newFile += line  
      end

      File.open(podspecName, 'w') { |file| file.write(newFile) }

      lintCmd = "pod spec lint #{podspecName}" + (force == true ? ' --allow-warnings' : '')
      lint = system(lintCmd)

      if lint == false
        puts "Linting failed, see errors. If its just a warning run with --force argument"
        exit
      end

      pushCmd = "pod repo push #{repoName} #{podspecName}" + (force == true ? ' --allow-warnings' : '')
      repoPush = system(pushCmd)

      if repoPush == false
        puts "Push failed, see errors."
        exit
      end

      addExecute = system('git add .')

      if addExecute == false 
        puts "Could not add files, consider finishing by hand and not the script"
        exit
      end

      commitExecute = system('git commit -m "[Versioning] Updating podspec"')

      if commitExecute == false 
        puts "Could not commit files, consider finishing by hand and not the script"
        exit
      end

      pushToServer = system('git push origin master')

      if pushToServer == false 
        puts "Could not push to server, consider finishing by hand and not the script"
        exit
      end
    end
  end
end
