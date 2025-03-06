# Updated routes for social media controllers

# YouTube routes
get "/youtube", YoutubeController, :show
get "/youtube/upload", YoutubeController, :upload_form
post "/youtube/upload", YoutubeController, :upload_video
post "/youtube/search", YoutubeController, :search
get "/youtube/connect", YoutubeController, :connect
get "/youtube/auth/callback", YoutubeController, :auth_callback

# Twitter routes
get "/twitter", TwitterController, :show
get "/twitter/tweet", TwitterController, :tweet_form
post "/twitter/tweet", TwitterController, :post_tweet
get "/twitter/connect", TwitterController, :connect
get "/twitter/auth/callback", TwitterController, :auth_callback
delete "/twitter/tweet/:id", TwitterController, :delete_tweet

# Instagram routes
get "/instagram", InstagramController, :show
get "/instagram/upload", InstagramController, :upload_form
post "/instagram/upload", InstagramController, :upload_media
get "/instagram/connect", InstagramController, :connect
get "/instagram/auth/callback", InstagramController, :auth_callback

# TikTok routes
get "/tiktok", TiktokController, :show
get "/tiktok/upload", TiktokController, :upload_form
post "/tiktok/upload", TiktokController, :upload_video
get "/tiktok/connect", TiktokController, :connect
get "/tiktok/auth/callback", TiktokController, :auth_callback
