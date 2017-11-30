require "podspecpush/version"
require 'trollop'

module Podspecpush
  class PodPush
    def push
      opts = Trollop::options do
        opt :repo, "Repo name", :type => :string
        opt :sources, "List of private repo sources to consider when linting private repo", :type => :string
        opt :force, "Pod verify & push with warnings"
        opt :privateRepo, "If set, assume repo is private and skip public checks"
      end
      Trollop::die :repo, "Repo must be provided" if opts[:repo] == nil

      force = opts[:force]
      repoName = opts[:repo]
      privateRepo = opts[:privateRepo]
      sources = opts[:sources]

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
      
      isPrivateFlag = (privateRepo == true ? ' --private' : '')
      sourcesFlag = (sources == nil ? '' : " --sources=#{sources},https://github.com/CocoaPods/Specs.git")
      disallowWarningsLint = "pod spec lint #{podspecName}" + isPrivateFlag + sourcesFlag
      allowWarningsLint = disallowWarningsLint + " --allow-warnings"

      lintCmd = (force == true ? allowWarningsLint : disallowWarningsLint)
      lint = system(lintCmd)

      if lint == false
        puts "Linting failed, try again by allowing warnings? [Y/n]"
        decision = gets.chomp.downcase
        if decision == "y"
          tryAgainCmd = allowWarningsLint
          tryAgain = system(tryAgainCmd)
          
          if tryAgain == false
            puts "Even with warnings, something is wrong. Look for any errors"
            exit
          else
            puts "Proceeding by allowing warnings"
          end
        else
          exit
        end
      end

      exit

      pushCmd = "pod repo push #{repoName} #{podspecName} --allow-warnings"
      repoPush = system(pushCmd)

      if repoPush == false
        puts "Push failed, see errors."
        exit
      end

      addExecute = system('git add .')

      if addExecute == false 
        puts "Could not add files to git, consider finishing by hand by performing a git add, commit, and push. Your spec repo should be up to date"
        exit
      end

      commitExecute = system('git commit -m "[Versioning] Updating podspec"')

      if commitExecute == false 
        puts "Could not commit files, consider finishing by hand by performing a git commit and push. Your spec repo should be up to date"
        exit
      end

      pushToServer = system('git push origin master')

      if pushToServer == false 
        puts "Could not push to server, consider finishing by hand by performing a git push. Your spec repo should be up to date"
        exit
      end
    end
  end
end
