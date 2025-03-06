defmodule MyappWeb.TwitterController do
  @moduledoc """
  Controller for Twitter-related web interface.
  
  This controller handles web requests related to Twitter functionality,
  providing a user interface for interacting with the Twitter API and
  related features implemented in the Myapp.SocialMedia.Twitter module.
  """
  use MyappWeb, :controller
  
  import MyappWeb.SocialMediaController, only: [
    validate_provider: 1,
    handle_connect: 3,
    handle_auth_callback: 3,
    handle_post: 5,
    handle_media_upload: 5,
    validate_media_upload: 1,
    parse_hashtags: 1,
    get_current_user_id: 1,
    check_auth: 3,
    get_expiry_datetime: 1
  ]
  
  alias Myapp.SocialMedia.Twitter
  alias Myapp.SocialAuth.Twitter, as: TwitterAuth

  @doc """
  Renders the Twitter page.
  
  This action displays the main Twitter interface where users can interact
  with Twitter-related features such as posting tweets, account management,
  and other Twitter API functionality.
  
  Assigns:
    * `connected` - Boolean indicating whether the user is connected to Twitter
    * `recent_tweets` - List of recent tweets if connected
  """
  def show(conn, _params) do
    user_id = get_current_user_id(conn)
    {connected, recent_tweets} = case check_auth(conn, "twitter", user_id) do
      {:ok, status} ->
        case Twitter.get_timeline(user_id) do
          {:ok, tweets} ->
            {true, tweets}
          _ ->
            {true, []}
        end
      _ ->
        {false, []}
    end
    
    conn
    |> assign(:connected, connected)
    |> assign(:recent_tweets, recent_tweets)
    |> render(:show)
  end

  @doc """
  Renders the tweet composition form.

  This action displays a form where users can compose and post tweets.
  It first checks if the user is connected to Twitter (authenticated)
  before rendering the form.

  Assigns:
    * `connected` - Boolean indicating whether the user is connected to Twitter
  """
  def tweet_form(conn, _params) do
    user_id = get_current_user_id(conn)
    case check_auth(conn, "twitter", user_id) do
      {:ok, _status} ->
        conn
        |> assign(:connected, true)
        |> render(:tweet_form)
      _ ->
        conn
        |> put_flash(:error, "You need to connect to Twitter before posting tweets")
        |> redirect(to: ~p"/twitter")
    end
  end

  @doc """
  Processes the tweet form submission.

  This action handles the tweet posting by:
  1. Validating the submitted content
  2. Posting the tweet to Twitter via the Twitter module
  3. Redirecting back with appropriate success/error messages

  Params:
    * `tweet` - The tweet parameters including text and media
  """
  def post_tweet(conn, %{"tweet" => tweet_params} = _params) do
    user_id = get_current_user_id(conn)
    case check_auth(conn, "twitter", user_id) do
      {:ok, _status} ->
        # Extract content and set defaults
        content = tweet_params["text"] || ""
        hashtags = parse_hashtags(tweet_params["hashtags"] || "")
        
        # Process media upload
        media_result = case validate_media_upload(tweet_params) do
          {:ok, media_path, media_type} ->
            handle_media_upload(conn, "twitter", media_path, [
              media_type: media_type
            ], user_id)
          {:ok, nil, _} ->
            {:ok, []}
          {:error, reason} -> 
            {:error, reason}
        end
        
        case media_result do
          {:ok, media_ids} ->
            # Create the post with media IDs if available
            options = [
              reply_settings: tweet_params["reply_settings"] || "everyone",
              hashtags: hashtags,
              media_ids: media_ids
            ]
            
            case handle_post(conn, "twitter", content, options, user_id) do
              {:ok, _response} ->
                conn
                |> put_flash(:info, "Tweet successfully posted to Twitter")
                |> redirect(to: ~p"/twitter")
              {:error, reason} ->
                conn
                |> put_flash(:error, "Failed to post tweet: #{reason}")
                |> redirect(to: ~p"/twitter/tweet")
            end
            
          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to upload media: #{reason}")
            |> redirect(to: ~p"/twitter/tweet")
        end

      _ ->
        conn
        |> put_flash(:error, "You need to connect to Twitter before posting tweets")
        |> redirect(to: ~p"/twitter")
    end
  end

  @doc """
  Initiates the OAuth flow to connect to Twitter.

  This action redirects the user to the Twitter OAuth consent page.
  """
  def connect(conn, params) do
    handle_connect(conn, "twitter", params)
  end

  @doc """
  Handles the OAuth callback from Twitter.

  This action processes the OAuth callback, exchanges the code for tokens,
  and stores the tokens in the session.

  Params:
    * `code` - The authorization code returned by Twitter
  """
  def auth_callback(conn, params) do
    handle_auth_callback(conn, "twitter", params)
  end

  @doc """
  Deletes a tweet.

  This action handles the deletion of a tweet.

  Params:
    * `id` - The ID of the tweet to delete
  """
  def delete_tweet(conn, %{"id" => tweet_id}) do
    user_id = get_current_user_id(conn)
    case check_auth(conn, "twitter", user_id) do
      {:ok, _status} ->
        case Twitter.delete_post(user_id, tweet_id) do
          {:ok, _response} ->
            conn
            |> put_flash(:info, "Tweet successfully deleted")
            |> redirect(to: ~p"/twitter")
          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to delete tweet: #{reason}")
            |> redirect(to: ~p"/twitter")
        end
      _ ->
        conn
        |> put_flash(:error, "You need to connect to Twitter before deleting tweets")
        |> redirect(to: ~p"/twitter")
    end
  end
end
