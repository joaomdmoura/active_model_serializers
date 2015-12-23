require 'bundler/gem_tasks'
require 'git'
require 'benchmark'
require 'rake/testtask'
require 'fileutils'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.ruby_opts = ['-r./test/test_helper.rb']
  t.verbose = true
end

ROOT = File.expand_path('..', __FILE__)
task :temp_dir do
  tmpdir = 'tmp/bench'
  FileUtils.rm_rf(tmpdir)
  FileUtils.mkdir_p(tmpdir)
  Dir[File.join(ROOT, 'test', '**', '*_benchmark.rb')].each do |file|
    FileUtils.cp(file, File.join(tmpdir, File.basename(file)))
  end
  at_exit { FileUtils.rm_rf(tmpdir) }
end

task :benchmark_tests do
  Rake::Task[:temp_dir].invoke unless File.directory?('tmp/bench')
  system("bundle exec ruby -Ilib:test tmp/bench/*.rb")
end

task benchmark: [:temp_dir] do
  @git = Git.init('.')
  ref  = @git.current_branch

  actual = run_benchmark_spec ref
  master = run_benchmark_spec 'master'

  @git.checkout(ref)

  puts "\n\nResults ============================\n"
  puts "------------------------------------~> (Branch) MASTER"
  puts master
  puts "------------------------------------\n\n"

  puts "------------------------------------~> (Actual Branch) #{ref}"
  puts actual
  puts "------------------------------------"
end

def run_benchmark_spec(ref)
  @git.checkout(ref)
  response = Benchmark.realtime {
    Rake::Task['benchmark_tests'].execute
  }
  Rake::Task['benchmark_tests'].reenable
  response
end
