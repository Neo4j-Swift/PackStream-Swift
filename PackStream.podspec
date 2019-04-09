Pod::Spec.new do |s|

  s.name         = "PackStream"
  s.version      = "1.1.0"
  s.summary      = "PackStream implementation in Swift"

  s.description  = <<-DESC
PackStream is a binary message format very similar to [MessagePack](http://msgpack.org). It can be used stand-alone, but it has been built as a message format for use in the Bolt protocol to communicate between the Neo4j server and its clients.

This implementation is written in Swift, primarily as a dependency for the Swift Bolt implementation. That implementation will in turn provide Theo, the Neo4j Swift driver, with Bolt support.
                   DESC

  s.homepage     = "https://github.com/neo4j-swift/PackStream-Swift"

  s.authors            = { "Niklas Saers" => "niklas@saers.com" }
  s.social_media_url   = "http://twitter.com/niklassaers"

  s.license      = { :type => "BSD", :file => "LICENSE" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/neo4j-swift/PackStream-Swift.git", :tag => "#{s.version}" }
  s.source_files  = "Sources"

end
