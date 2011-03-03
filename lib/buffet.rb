# === TERMINOLOGY
#
# Proxy Interface:: - the class that defines the methods implemented by each proxy
# Proxy Implementation:: - a "concrete implementation" of the "abstract" Proxy "interface" for an individual 3rd-party service
# Proxy:: - shorthand for Proxy Implementation
#
#
# === TO DO
#
# * Write a companion gem called "meal ticket" to handle 3rd-party auth
#
# === NOTES / OPEN QUESTIONS
#
# ==== Maintain record of copies across services?
# When writing an object out to a service, can/should we track that it's the same as the one we pulled from another
# service? Eg, if I pull a photo from FB and post it to Flickr, from the user's perspective I've duped the photo
# in the second location but programatically, they're two different things. So for instance if we were to then show
# all photos for a user, we'd show it twice. Is that correct? Should we only show it once? Not sure how we'd be
# able to persist those connections.  Maybe there's a way we could link them in their metadata? When we push the photo
# to flickr, give it some hidden value that lets us associate it with the FB version?
#
# ==== Non-standard response snippets
# We've floated the idea of having pure types include a hash of "extras". This would be data returned by a given service
# that doesn't fall within the generic feature set we've defined but nonetheless might be useful to a developer. We want
# to make this information available, but not TOO easy to get to, because after all, the whole point of this gem is to
# standardize. But hopefully the +extras+ hash will make life easier for developers who want a little more control,
# and also help us determine what features we should add to the official feature set.
#
module Buffet

  # The user object shouldn't be one of ours. All we care about are the tokens for each service
  # the gem consumer wants to write to. So when the consumer passes a "user" to one of our methods,
  # we need to check for the presence of a "get_{facebook}_token" method or whatever service is being called.
  #
  # Not sure how to accomplish this technically. It could be a single method that's called from each pure-type
  # method. It could be wrapped up in a User module that is included in the consumer's User class.
  #
  # Also, need a way of listing services linked to this user.
  #
  # Where do we handle permissions? Do we need to track it somewhere, or just let the request fail if you try to do something
  # you're not auth'd for? We could know before we make the request, but that seems like more work and more
  # complexity/fragility. Probably better to make the request and let it fail? The consumer should have requested the
  # appropriate API permissions and know what methods are available given the permissions requested. Maybe we do, however,
  # need to help the consumer know what permissions they need to ask for?
  module User

    # This method is only conditionally necessary. If the consumer never uses FB it doesn't matter if they implement
    # this method on their user object. So is it okay for our module to define and raise an error on this method?
    # At least this way, if the user DOES try to connect to FB but hasn't implemented the method they'll get the
    # proper error.
    #
    # Also, can we dynamically create these methods based on the proxies we've defined? Seems silly to write the same
    # code over again for every proxy. Maybe we need a list of proxies somewhere?
    #
    # What if someone adds their own proxy but it isn't in the official list? We absolutely want to allow 3rd-party proxies.
    # Hopefully those will ultimately get folded in to this gem, but we need to make it easy for people to write them.
    # How will those proxies ensure data consistency with respect to tokens? However WE do it needs to be extensible by
    # consumers.
    def get_facebook_token
      raise "needs to implement 'get_facebook_token'"
    end
  end

  class Album

    attr_accessor :title, :id, :service, :user
    
    # PRIVATE PROPERTIES
    # album.user - save this for making future requests?

    # Optional +user+ parameter scopes the call to things this user owns. Called with no user, this method searches
    # across all publicly available information.
    #
    # Optional +options+ hash scopes the call by various parameters. Parameters currently in consideration include:
    #
    # * id (may be a rare use case, since if you have the ID you probably have the rest of the album too)
    # * name
    # * created
    # * services
    #
    # Parameters currently implemented include:
    #
    # * _none yet implemented_
    #
    # Since we can make requests to different services in parallel, we can look on Facebook/Flickr/Picasa for an album named
    # "summer 2010" just as easily as looking on a single service.
    #
    def self.find(user = nil, options = {})

      # We can only make the requests in parallel if they're made OUTSIDE the proxies.
      # The FB proxy doesn't know that the Flickr proxy is making a request. The only guy who knows is the pure type calling
      # the proxy method. So, the pure type instantiates the Hydra and passes it to the proxy.  Biggest open
      # question here is how the responses are then distributed back to the proxies.

    end

    # makes an HTTP call to load the album's images
    def images
    end
  end

  # how do we deal with different sizes?
  class Image

    # PRIVATE PROPERTIES
    # image.user?

    def self.find(user, options = {})
    end

  end

  ###########################################################
  #
  # The ProxyInterface class defines the interface for the proxy implementations, raising errors if a method is undefined. eg:
  #
  #   def find_album(user, options = {})
  #     raise "find_album not implemented"
  #   end
  #
  # The proxy implementations override these methods, preventing the errors from being raised. Proxy methods are
  # translating from the syntax of pure-type methods to the syntax of API access. They're breaking object-based
  # method calls out into endpoint-based method calls... but still in a generic way. Then it's up to the individual
  # proxies to translate the generic API call to the proper service-specific endpoint.
  #
  # Proxies should implement finder methods for each attribute on a pure type. Eg, if an image has +created_at+ and +caption+
  # fields, the consumer should be able to call Image.find(user, {:caption => "sally fields"}) and the proxy should implement
  # the find_by_caption method. Now, it may not be feasible to search on every single attribute - but that's the level of
  # granularity we want to use for these methods.
  #
  # Proxy methods should be able to take an option Hydra object in which to queue its request. If no hydra is provided,
  # the proxy method should create its own HTTP connection. All request multithreading should happen at the pure-type level.
  #
  class ProxyInterface

    ["find_album",
     "find_image",
     "find_album_by_id",
     "find_album_images"].each do |method|

      # class_eval these into methods that look like:
      # def find_album
      #   raise 'needs to implement "find_album"'
      # end
      #
      # TODO: make sure tests hit all these methods for every proxy.

    end
  end

  ###########################################################
  #
  # The individual service proxies implement the methods in the Proxy interface. This is where we make the actual API
  # call. These methods are responsible for parsing the JSON/XML response and returning pure types.
  #
  # We may want to specify what types of media this service returns, so we don't have to hit photo services when we're
  # interested in videos. Though, maybe we can do that by having a photo service return an empty result set for a
  # find_videos method.
  #
  # The proxy is responsible for anything else service-specific. Eg, flickr requests are signed with a hash of the parameters
  # you're passing. That would happen in the proxy.
  #
  class FlickrProxy < Proxy
  end
end
