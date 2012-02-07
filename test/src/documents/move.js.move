hello = ^(name){ "Hello "+name }
repeat {times: 3} ^{
  print hello {name: "John"}
}