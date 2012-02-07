---
title: 'Ruby!'
---

# The Greeter class
class Greeter
	def initialize(name)
		@name = name.capitalize
	end

	def salute
		puts "Hello #{@name}!"
	end
end
 
# Create a new object
g = Greeter.new("world")
 
# Output "Hello World!"
g.salute

# Document title
puts "This page's title is #{document['title']}"