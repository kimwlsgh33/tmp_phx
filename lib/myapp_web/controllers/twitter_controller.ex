defmodule MyappWeb.TwitterController do
  @moduledoc """
  Controller for Twitter-related web interface.
  
  This controller handles web requests related to Twitter functionality,
  providing a user interface for interacting with the Twitter API and
  related features implemented in the Myapp.SocialMedia.Twitter module.
  """
  use MyappWeb, :controller
  
  import MyappWeb.SocialMediaController, only: [validate_provider: 1]
  
  alias Myapp.SocialMedia.Twitter
  alias Myapp.SocialAuth.Twitter, as: TwitterAuth
  alias Myapp.SocialMedia.Utils, as: SocialMediaUtils

  # Get current user_id from session or conn
  defp get_current_user_id(conn) do
    # This should be replaced with your actual user_id retrieval logic
    # For example, you might get it from the session or the conn assigns
    conn.assigns[:current_user_id] || "default_user"
  end

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
    {connected, recent_tweets} = case Twitter.authenticated?(user_id) do
      {:ok, %{authenticated: true}} ->
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
    case Twitter.authenticated?(user_id) do
      {:ok, %{authenticated: true}} ->
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
    * `text` - The text content of the tweet
  """
  def post_tweet(conn, %{"tweet" => tweet_params} = _params) do
    user_id = get_current_user_id(conn)
    case Twitter.authenticated?(user_id) do
      {:ok, %{authenticated: true}} ->
        # Extract content and set defaults
        content = tweet_params["text"] || ""
        
        # Process media upload outside of the with statement
        media_upload_result = case SocialMediaUtils.validate_media_upload(tweet_params) do
          {:ok, media_path} when is_binary(media_path) ->
            # Get mime type from the file extension
            mime_type = MIME.from_path(media_path)
            Twitter.upload_media(user_id, media_path, mime_type)
          {:ok, nil} ->
            {:ok, []}
          error -> 
            error
        end
        
        # Now we can use the result in a simpler with statement
        post_result = 
          with {:ok, media_ids} <- media_upload_result,
               # Additional options like reply settings
               options = [reply_settings: tweet_params["reply_settings"] || "everyone"],
               {:ok, response} <- Twitter.create_post(user_id, content, media_ids, options) do
            {:ok, response}
          else
            {:error, reason} -> {:error, reason}
          end

        case post_result do
          {:ok, _response} ->
            conn
            |> put_flash(:info, "Tweet successfully posted to Twitter")
            |> redirect(to: ~p"/twitter")
          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to post tweet: #{reason}")
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
  def connect(conn, _params) do
    case TwitterAuth.generate_auth_url() do
      {:ok, oauth_url} ->
        redirect(conn, external: oauth_url)
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to connect to Twitter: #{reason}")
        |> redirect(to: ~p"/twitter")
    end
  end

  @doc """
  Handles the OAuth callback from Twitter.

  This action processes the OAuth callback, exchanges the code for tokens,
  and stores the tokens in the session.

  Params:
    * `code` - The authorization code returned by Twitter
  """
  def auth_callback(conn, %{"code" => code}) do
    case TwitterAuth.exchange_code_for_token(code) do
      {:ok, tokens} ->
        conn
        |> store_provider_tokens(:twitter, tokens)
        |> put_flash(:info, "Successfully connected to Twitter")
        |> redirect(to: ~p"/twitter")
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to connect to Twitter: #{reason}")
        |> redirect(to: ~p"/twitter")
    end
  end

  @doc """
  Deletes a tweet.

  This action handles the deletion of a tweet.

  Params:
    * `id` - The ID of the tweet to delete
  """
  def delete_tweet(conn, %{"id" => tweet_id}) do
    user_id = get_current_user_id(conn)
    case Twitter.authenticated?(user_id) do
      {:ok, %{authenticated: true}} ->
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

  # Validate media upload is now handled by SocialMediaUtils.validate_media_upload/1
  
  # Private functions
  
  @doc """
  Stores provider tokens in the session.
  
  This function stores the authentication tokens for a specific provider in the session.
  
  Args:
    * `conn` - The connection struct
    * `provider` - The provider name (atom or string)
    * `tokens` - The tokens to store
  """
  defp store_provider_tokens(conn, provider, tokens) do
    put_session(conn, "#{provider}_tokens", tokens)
  end
end
