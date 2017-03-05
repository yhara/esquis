require 'bundler/setup'

file 'lib/esquis/parser.ry' => 'lib/esquis/parser.ry.erb' do
  sh "erb lib/esquis/parser.ry.erb > lib/esquis/parser.ry"
end

file 'lib/esquis/parser.rb' => 'lib/esquis/parser.ry' do
  cmd = "racc -o lib/esquis/parser.rb lib/esquis/parser.ry"
  cmd.sub!("racc", "racc --debug") if ENV["DEBUG"] == "1"
  sh cmd
end

desc "run test"
task :test => 'lib/esquis/parser.rb' do
  if ENV["F"]
    sh "rspec --fail-fast"
  else
    sh "rspec"
  end
end

task :parser => 'lib/esquis/parser.rb'
task :default => :test
