require 'octokit'
require 'base64'
require 'rainbow'
require 'progress_bar'
require 'ghuls/lib'

module GHULS
  class CLI
    # Parses the arguments (typically ARGV) into a usable hash.
    # @param args [Array] The arguments to parse.
    def parse_options(args)
      args.each do |arg|
        case arg
        when '-h', '--help' then @opts[:help] = true
        when '-un', '--user' then @opts[:user] = GHULS::Lib.get_next(arg, args)
        when '-pw', '--pass' then @opts[:pass] = GHULS::Lib.get_next(arg, args)
        when '-t', '--token' then @opts[:token] = GHULS::Lib.get_next(arg, args)
        when '-g', '--get' then @opts[:get] = GHULS::Lib.get_next(arg, args)
        when '-d', '--debug' then @opts[:debug] = true
        when '-r', '--random' then @opts[:get] = nil
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
        puts 'Error: authentication failed, check your username/password ' \
             ' or token'
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
        puts Rainbow("#{l}: #{p}%").color(color)
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
        user_percents = GHULS::Lib.analyze_user(@opts[:get], @gh)
        increment
        org_percents = GHULS::Lib.analyze_orgs(@opts[:get], @gh)
        increment
        if !user_percents.nil?
          puts "Getting language data for #{user[:username]}..."
          output(user_percents)
        else
          puts 'Could not find any personal data to analyze.'
        end
        if !org_percents.nil?
          puts 'Getting language data for their organizations...'
          output(org_percents)
        else
          puts 'Could not find any organizaztion data to analyze.'
        end
      end
      exit
    end
  end
end
