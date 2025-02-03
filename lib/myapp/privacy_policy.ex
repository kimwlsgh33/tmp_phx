defmodule Myapp.PrivacyPolicy do
  @moduledoc """
  Handles privacy policy data management and retrieval.
  """

  use Gettext, backend: Myapp.Gettext
  
  @privacy_policy_path_v1 "priv/privacy_policy/v1.json"

  @doc """
  Gets the privacy policy content with localization support.
  Returns {:ok, policy} on success, {:error, reason} on failure

  ## Parameters
    * locale - Optional locale to get the policy in. Defaults to current locale.
  """
  def get_policy(locale \\ nil) do
    with {:ok, content} <- File.read(Application.app_dir(:myapp, @privacy_policy_path_v1)),
         {:ok, policy} <- Jason.decode(content) do
      # Set the locale for gettext if provided
      if locale, do: Gettext.put_locale(Myapp.Gettext, locale)
      
      localized_policy = localize_policy(policy)
      {:ok, localized_policy}
    end
  end

  # Localizes the policy content using Gettext
  defp localize_policy(%{"document" => document} = policy) do
    localized_document = 
      document
      |> localize_sections()
      |> Map.put("index", localize_index(document["index"]))

    Map.put(policy, "document", localized_document)
  end

  defp localize_sections(%{"sections" => sections} = document) do
    localized_sections = Enum.map(sections, &localize_section/1)
    Map.put(document, "sections", localized_sections)
  end

  defp localize_section(%{"chapters" => chapters} = section) do
    localized_chapters = Enum.map(chapters, &localize_chapter/1)
    section
    |> Map.put("chapters", localized_chapters)
    |> Map.update!("title", fn text -> 
      Gettext.dgettext(Myapp.Gettext, "privacy_policy", text)
    end)
  end

  defp localize_chapter(chapter) do
    chapter
    |> Map.update!("title", fn text -> 
      Gettext.dgettext(Myapp.Gettext, "privacy_policy", text)
    end)
    |> Map.update("content", [], fn contents -> 
      Enum.map(contents, fn content -> 
        Map.update!(content, "text", fn text ->
          Gettext.dgettext(Myapp.Gettext, "privacy_policy", text)
        end)
      end)
    end)
  end

  defp localize_index(%{"items" => items} = index) do
    localized_items = Enum.map(items, fn item ->
      Map.update!(item, "title", fn text ->
        Gettext.dgettext(Myapp.Gettext, "privacy_policy", text)
      end)
    end)
    
    index
    |> Map.put("items", localized_items)
    |> Map.update!("title", fn text ->
      Gettext.dgettext(Myapp.Gettext, "privacy_policy", text)
    end)
    |> Map.update!("subtitle", fn text ->
      Gettext.dgettext(Myapp.Gettext, "privacy_policy", text)
    end)
  end
end
