require 'paint'
require 'progress_bar'
require 'ghuls/lib'
require 'array_utility'
require 'string-utility'
require 'github/calendar'

module GHULS
  class CLI
    using ArrayUtility
    using StringUtility

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
      begin
        @ghuls = GHULS::Lib.new(@opts)
      rescue Octokit::Unauthorized
        puts 'Error: authentication failed, check your username/password or token'
      end
      increment
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
        color = @ghuls.get_color_for_language(l.to_s)
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
      user_langs = @ghuls.get_user_langs(@opts[:get])
      increment
      org_langs = @ghuls.get_org_langs(@opts[:get])
      increment
      if !user_langs.empty?
        puts "Getting language data for #{username}..."
        user_percents = @ghuls.get_language_percentages(user_langs)
        output(user_percents)
      else
        puts 'Could not find any personal data to analyze.'
      end
      if !org_langs.empty?
        puts 'Getting language data for their organizations...'
        org_percents = @ghuls.get_language_percentages(org_langs)
        output(org_percents)
      else
        puts 'Could not find any organization data to analyze.'
      end

      return if org_langs.empty? && user_langs.empty?

      user_langs.update(org_langs) { |_, v1, v2| v1 + v2 }
      puts 'Getting combined language data...'
      output(@ghuls.get_language_percentages(user_langs))
    end

    def fork_data(repos)
      repos[:public].each do |r|
        next if repos[:forks].include? r
        fsw = @ghuls.get_forks_stars_watchers(r)
        puts "#{r}: #{fsw[:forks]} forks, #{fsw[:stars]} stars, and #{fsw[:watchers]} watchers"
      end
    end

    def follower_data(username)
      follows = @ghuls.get_followers_following(@opts[:get])
      followers = Paint["#{follows[:followers]} followers", :green]
      following = Paint["following #{follows[:following]}", '#FFA500']
      puts "#{username} has #{followers} and is #{following} people"
    end

    def issue_data(repos)
      puts 'Getting issue and pull request data...'
      repos[:public].each do |r|
        next if repos[:forks].include? r
        things = @ghuls.get_issues_pulls(r)
        open_issues = Paint["#{things[:issues][:open]} open", :green]
        closed_issues = Paint["#{things[:issues][:closed]} closed", :red]
        open_pulls = Paint["#{things[:pulls][:open]} open", :green]
        closed_pulls = Paint["#{things[:pulls][:closed]} closed", :red]
        merged_pulls = Paint["#{things[:pulls][:merged]} merged", :magenta]
        puts "Issue data for #{r}: #{open_issues} and #{closed_issues}"
        puts "Pull data for #{r}: #{open_pulls}, #{merged_pulls}, and #{closed_pulls}"
      end
    end

    def calendar_data(username)
      puts "Total contributions this year: #{GitHub::Calendar.get_total_year(username).to_s.separate}"
      puts "An average day has #{GitHub::Calendar.get_average_day(username).to_s.separate} contributions"
      puts "An average week has #{GitHub::Calendar.get_average_week(username).to_s.separate} contributions"
      puts "An average month has #{GitHub::Calendar.get_average_month(username).to_s.separate} contributions"
      GitHub::Calendar.get_monthly(username).each do |month, amount|
        month_name = case month
                     when '01' then 'January'
                     when '02' then 'February'
                     when '03' then 'March'
                     when '04' then 'April'
                     when '05' then 'May'
                     when '06' then 'June'
                     when '07' then 'July'
                     when '08' then 'August'
                     when '09' then 'September'
                     when '10' then 'October'
                     when '11' then 'November'
                     when '12' then 'December'
                     else month
                     end
        puts "#{month_name} had #{amount.to_s.separate} contributions"
      end
    end

    # Simply runs the program.
    def run
      puts @usage if failed?
      puts @help if @opts[:help]
      exit if failed?
      increment
      @opts[:get] = @ghuls.get_random_user if @opts[:get].nil?

      user = @ghuls.get_user_and_check(@opts[:get])
      if !user
        puts 'Sorry, something wen\'t wrong.'
        puts "We could not find any user named #{@opts[:get]}."
        puts 'If you believe this is an error, please report it as a bug.'
      else
        @repos = @ghuls.get_user_repos(@opts[:get])
        @org_repos = @ghuls.get_org_repos(@opts[:get])
        language_data(user[:username])
        puts 'Getting forks, stars, and watchers of user repositories...'
        fork_data(@repos)
        puts 'Getting forks, stars, and watchers of organization repositories...'
        fork_data(@org_repos)
        follower_data(user[:username])
        issue_data(@repos)
        issue_data(@org_repos)
        calendar_data(user[:username])
      end
      exit
    end
  end
end
