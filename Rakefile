require 'bundler/setup'

file 'lib/esquis/parser.ry' => 'lib/esquis/parser.ry.erb' do
  sh "erb lib/esquis/parser.ry.erb > lib/esquis/parser.ry"
end

file 'lib/esquis/parser.rb' => 'lib/esquis/parser.ry' do
  cmd = "racc -o lib/esquis/parser.rb lib/esquis/parser.ry"
  cmd.sub!("racc", "racc --debug") if ENV["DEBUG"]
  sh cmd
end

desc "run test"
task :test => 'lib/esquis/parser.rb' do
  sh "rspec"
end

task :default => :test
