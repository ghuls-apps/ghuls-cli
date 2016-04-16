Gem::Specification.new do |s|
  s.name = 'ghuls'
  s.version = '1.7.2'
  s.required_ruby_version = '>= 2.0'
  s.authors = ['Eli Foster']
  s.description = 'Getting GitHub repository language data by user! It also ' \
                  'has a web alternative at http://ghuls.herokuapp.com'
  s.email = 'elifosterwy@gmail.com'
  s.files = [
    'lib/ghuls.rb',
    'lib/ghuls/cli.rb',
    'bin/ghuls',
    'CHANGELOG.md'
  ]
  s.executables = 'ghuls'
  s.homepage = 'http://ghuls.herokuapp.com'
  s.summary = 'GHULS: GitHub User Language Statistics'
  s.license = 'MIT'
  s.add_runtime_dependency('paint', '~> 1.0')
  s.add_runtime_dependency('ghuls-lib', '~> 2.3')
  s.add_runtime_dependency('progress_bar', '~> 1.0')
  s.add_runtime_dependency('array_utility', '~> 1.0')
  s.add_runtime_dependency('string-utility', '~> 2.7')
  s.add_runtime_dependency('github-calendar', '~> 1.2')
end
