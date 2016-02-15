require 'paint'
require 'progress_bar'
require 'ghuls/lib'
require 'array_utility'

module GHULS
  class CLI
    using ArrayUtility

    # Parses the arguments (typically ARGV) into a usable hash.
    # @param args [Array] The arguments to parse.
    def parse_options(args)
      args.each do |arg|
        case arg
        when '-h', '--help' then @opts[:help] = true
        when '-un', '--user' then @opts[:user] = args.next(arg)
        when '-pw', '--pass' then @opts[:pass] = args.next(arg)
        when '-t', '--token' then @opts[:token] = args.next(arg)
        when '-g', '--get' then @opts[:get] = args.next(arg)
        when '-d', '--debug' then @opts[:debug] = true
        when '-r', '--random' then @opts[:get] = nil
        else next
        end
      end
    end

    def increment
      @bar.increment! if @opts[:debug]
    end

    # Creates a new instance of GHULS::CLI
    # @param args [Array] The arguments for the CLI.
    def initialize(args = ARGV)
      @opts = {
        help: false,
        user: nil,
        pass: nil,
        token: nil,
        get: nil,
        debug: nil
      }

      @usage = 'Usage: ghuls [-h] [-un] username [-pw] password [-t] token ' \
               '[-g] username [-r] [-d]'
      @help = "-h, --help     Show helpful information.\n" \
              "-d, --debug    Provide debug information.\n" \
              "-un, --user    The username to log in as.\n" \
              "-pw, --pass    The password for that username.\n" \
              '-t, --token    The token to log in as. This will be preferred ' \
              "over username and password authentication.\n" \
              "-g, --get      The username/organization to analyze.\n" \
              "-r, --random   Use a random user.\n"

      parse_options(args)
      @bar = ProgressBar.new(5) if @opts[:debug]
      increment
      config = GHULS::Lib.configure_stuff(@opts)
      increment
      if config == false
        puts 'Error: authentication failed, check your username/password or token'
        exit
      end
      @gh = config[:git]
      @colors = config[:colors]
    end

    # Whether or not the script should fail.
    # @return [Boolean] False if it did not fail, true if it did.
    def failed?
      false if @opts[:help]
      true if @opts[:get].nil?
      true if @opts[:token].nil? && @opts[:user].nil?
      true if @opts[:token].nil? && @opts[:pass].nil?
    end

    def output(percents)
      percents.each do |l, p|
        color = GHULS::Lib.get_color_for_language(l.to_s, @colors)
        puts Paint["#{l}: #{p}%", color]
      end
    end

    def fail_after_analyze
      puts 'Sorry, something went wrong.'
      puts "We either could not find anyone under the name #{@opts[:get]}, " \
           'or we could not find any data for them.'
      puts 'Please try again with a different user. If you believe this is ' \
           'an error, please report it to the developer.'
      exit
    end

    # Gets and outputs language data for the user and their organizations.
    # @param username [String] The username of the user.
    def language_data(username)
      user_langs = GHULS::Lib.get_user_langs(@opts[:get], @gh)
      increment
      org_langs = GHULS::Lib.get_org_langs(@opts[:get], @gh)
      increment
      if !user_langs.empty?
        puts "Getting language data for #{username}..."
        user_percents = GHULS::Lib.get_language_percentages(user_langs)
        output(user_percents)
      else
        puts 'Could not find any personal data to analyze.'
      end
      if !org_langs.empty?
        puts 'Getting language data for their organizations...'
        org_percents = GHULS::Lib.get_language_percentages(org_langs)
        output(org_percents)
      else
        puts 'Could not find any organization data to analyze.'
      end

      return if org_langs.empty? && user_langs.empty?

      user_langs.update(org_langs) { |_, v1, v2| v1 + v2 }
      puts 'Getting combined language data...'
      output(GHULS::Lib.get_language_percentages(user_langs))
    end

    def fork_data(repos)
      repos[:public].each do |r|
        next if repos[:forks].include? r
        fsw = GHULS::Lib.get_forks_stars_watchers(r, @gh)
        puts "#{r}: #{fsw[:forks]} forks, #{fsw[:stars]} stars, and #{fsw[:watchers]} watchers"
      end
    end

    def follower_data(username)
      follows = GHULS::Lib.get_followers_following(@opts[:get], @gh)
      followers = Paint["#{follows[:followers]} followers", :green]
      following = Paint["following #{follows[:following]}", '#FFA500']
      puts "#{username} has #{followers} and is #{following} people"
    end

    def issue_data(repos)
      puts 'Getting issue and pull request data...'
      repos[:public].each do |r|
        next if repos[:forks].include? r
        things = GHULS::Lib.get_issues_pulls(r, @gh)
        open_issues = Paint["#{things[:issues][:open]} open", :green]
        closed_issues = Paint["#{things[:issues][:closed]} closed", :red]
        open_pulls = Paint["#{things[:pulls][:open]} open", :green]
        closed_pulls = Paint["#{things[:pulls][:closed]} closed", :red]
        merged_pulls = Paint["#{things[:pulls][:merged]} merged", :magenta]
        puts "Issue data for #{r}: #{open_issues} and #{closed_issues}"
        puts "Pull data for #{r}: #{open_pulls}, #{merged_pulls}, and #{closed_pulls}"
      end
    end

    # Simply runs the program.
    def run
      puts @usage if failed?
      puts @help if @opts[:help]
      exit if failed?
      increment
      @opts[:get] = GHULS::Lib.get_random_user(@gh) if @opts[:get].nil?

      user = GHULS::Lib.get_user_and_check(@opts[:get], @gh)
      if user == false
        puts 'Sorry, something wen\'t wrong.'
        puts "We could not find any user named #{@opts[:get]}."
        puts 'If you believe this is an error, please report it as a bug.'
      else
        @repos = GHULS::Lib.get_user_repos(@opts[:get], @gh)
        @org_repos = GHULS::Lib.get_org_repos(@opts[:get], @gh)
        language_data(user[:username])
        puts 'Getting forks, stars, and watchers of user repositories...'
        fork_data(@repos)
        puts 'Getting forks, stars, and watchers of organization repositories...'
        fork_data(@org_repos)
        follower_data(user[:username])
        issue_data(@repos)
        issue_data(@org_repos)
      end
      exit
    end
  end
end
