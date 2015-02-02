# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
User.destroy_all
View.destroy_all
Bench.destroy_all
Algorithm.destroy_all
Task.destroy_all

user = User.create!(name: 'Ran Xian', email: 'xianran@pku.edu.cn', password: '12345678')
view = View.generate!(user, name: 'Test-View', strategy: 'all')
bench1 = Bench.generate!(user, view, 
                               strategy: 'general',
                               name: 'General Benchmark', 
                               class_count: 5, 
                               sample_count: 2)
bench2 = Bench.generate!(user, view,
                               strategy: 'all',
                               name: "All Benchmark")
algorithm = Algorithm.generate!(user, name: 'my algorithm',
                                description: 'algorihm seed',
                                path: Rails.root.join('alg.zip').to_s)
task = Task.run!(user, bench1, algorithm)

puts task.inspect