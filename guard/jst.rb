require 'guard'
require 'guard/guard'
require 'lib/handlebars/handlebars'
require 'fileutils'

module Guard
  class JST < Guard


    DEFAULT_OPTIONS = {
      :hide_success => false,
      :all_on_start => false
    }

    # Initialize Guard::JST.
    #
    # @param [Array<Guard::Watcher>] watchers the watchers in the Guard block
    # @param [Hash] options the options for the Guard
    # @option options [String] :input the input directory
    # @option options [String] :output the output directory
    # @option options [Boolean] :hide_success hide success message notification
    # @option options [Boolean] :all_on_start generate all JavaScripts files on start
    #
    def initialize(watchers = [], options = {})
      watchers = [] if !watchers
      defaults = DEFAULT_OPTIONS.clone

      if options[:input]
        defaults.merge!({ :output => options[:input] })
        watchers << ::Guard::Watcher.new(%r{^#{ options[:input] }/(.+\.handlebars)$})
      end

      super(watchers, defaults.merge(options))
    end

    # Gets called once when Guard starts.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def start
      run_all if options[:all_on_start]
    end


    # Gets called when watched paths and files have changes.
    #
    # @param [Array<String>] paths the changed paths and files
    # @raise [:task_has_failed] when stop has failed
    #
    # Compiles templates from app/views/jst to public/javascripts/jst
    def run_on_change(paths)
      Parallel.each(paths, :in_threads => Parallel.processor_count) do |path|
        begin
          puts "Compiling: #{path}"
          Handlebars.compile_file path, 'app/views/jst', @options[:output]
        rescue Exception => e
          ::Guard::Notifier.notify(e.to_s, :title => path.sub('app/views/jst/', ''), :image => :failed)
        end
      end
    end

    # Gets called when all files should be regenerated.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def run_all
      UI.info "pre-compiling all handlebars templates in #{@options[:input]} to #{@options[:output]}"
      FileUtils.rm_r @options[:output] if File.exists?(@options[:output])
      Handlebars.compile @options[:input], @options[:output]
    end


    # Called on file(s) deletions that the Guard watches.
    #
    # @param [Array<String>] paths the deleted files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def run_on_deletion(paths)
      raise "doesnt work "
      # paths.each do |file|
      #   javascript = file.gsub(/(js\.coffee|coffee)$/, 'js')
      #   File.remove(javascript) if File.exists?(javascript)
      # end
    end

  end
end
