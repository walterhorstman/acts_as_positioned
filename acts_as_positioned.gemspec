$LOAD_PATH.push(File.expand_path('../lib', __FILE__))

Gem::Specification.new do |s|
  s.name = 'acts_as_positioned'
  s.version = '0.0.3'
  s.authors = ['Walter Horstman']
  s.email = ['walter.horstman@itonrails.com']
  s.summary = 'Lightweight ordering of models in ActiveRecord 3 or higher'
  s.description = 'This gem allows you to have ordered models. It is like the old acts_as_list, but very lightweight ' \
                  'and with an optimized SQL syntax.'
  s.homepage = 'http://github.com/walterhorstman/acts_as_positioned'

  s.files = Dir['lib/**/*', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency('activerecord', '>= 3')
  s.add_development_dependency('minitest')
  s.add_development_dependency('rake')
  s.add_development_dependency('rubocop')
  s.add_development_dependency('sqlite3')
end
