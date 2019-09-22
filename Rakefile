# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

desc 'Print help information'
task default: :help

desc 'Print help information'
task :help do
  system 'bundle exec rake -D'
end

desc 'Run the development console'
task :console do
  system './bin/console'
end

desc 'Compile all project Ruby files with warnings.'
task :compile do
  paths = Dir['**/*.rb', '**/*.gemspec', 'exe/broken_link_finder']
  paths.each do |f|
    puts "\nCompiling #{f}..."
    puts `ruby -cw #{f}`
  end
end
