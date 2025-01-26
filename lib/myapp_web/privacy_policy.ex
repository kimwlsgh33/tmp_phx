defmodule MyappWeb.PrivacyPolicy do
  @moduledoc """
  Handles privacy policy content and translations.
  Provides functions to fetch and format privacy policy sections with proper localization.
  """

  import MyappWeb.Gettext

  @doc """
  Gets a section of the privacy policy with proper localization.
  
  ## Parameters
    * section_id - The ID of the section to fetch
    * locale - Optional locale override. If not provided, uses the current locale
  
  ## Examples
      iex> get_section("introduction")
      %{title: "Welcome", content: "Welcome to our service..."}
  """
  def get_section(section_id, locale \\ nil) do
    Gettext.with_locale(locale || Gettext.get_locale(), fn ->
      case section_id do
        "introduction" ->
          %{
            type: "section",
            title: gettext("privacy_introduction_title"),
            content: gettext("privacy_introduction_content")
          }

        "section-1" ->
          %{
            type: "section",
            id: "section-1",
            number: "1",
            title: gettext("privacy_section_1_title"),
            summary: gettext("privacy_section_1_summary"),
            chapters: get_chapters(1)
          }

        "section-2" ->
          %{
            type: "section",
            id: "section-2",
            number: "2",
            title: gettext("privacy_section_2_title"),
            summary: gettext("privacy_section_2_summary"),
            chapters: get_chapters(2)
          }

        "section-3" ->
          %{
            type: "section",
            id: "section-3",
            number: "3",
            title: gettext("privacy_section_3_title"),
            summary: gettext("privacy_section_3_summary"),
            chapters: get_chapters(3)
          }

        _ ->
          nil
      end
    end)
  end

  @doc """
  Gets all sections of the privacy policy.
  
  ## Parameters
    * locale - Optional locale override
  
  ## Examples
      iex> get_all_sections()
      [%{id: "section-1", ...}, ...]
  """
  def get_all_sections(locale \\ nil) do
    Gettext.with_locale(locale || Gettext.get_locale(), fn ->
      [
        get_section("introduction"),
        get_section("section-1"),
        get_section("section-2"),
        get_section("section-3")
      ]
    end)
  end

  @doc """
  Gets the metadata for the privacy policy.
  
  ## Parameters
    * locale - Optional locale override
  
  ## Examples
      iex> get_metadata()
      %{version: "2.0.0", ...}
  """
  def get_metadata(locale \\ nil) do
    Gettext.with_locale(locale || Gettext.get_locale(), fn ->
      %{
        version: "2.0.0",
        schemaVersion: "2024.2",
        releaseDate: "2025-01-26",
        effectiveDate: "2025-02-01",
        language: Gettext.get_locale(),
        accessibility: %{
          role: "document",
          lang: "#{Gettext.get_locale()}-#{String.upcase(Gettext.get_locale())}",
          ariaLabel: gettext("privacy_policy_aria_label")
        }
      }
    end)
  end

  # Private functions

  defp get_chapters(section_number) do
    case section_number do
      1 -> [
        %{
          id: "chapter-1",
          type: "chapter",
          number: "1",
          title: gettext("privacy_section_1_chapter_1_title"),
          content: gettext("privacy_section_1_chapter_1_content")
        },
        %{
          id: "chapter-2",
          type: "chapter",
          number: "2",
          title: gettext("privacy_section_1_chapter_2_title"),
          content: gettext("privacy_section_1_chapter_2_content")
        }
      ]
      2 -> [
        %{
          id: "chapter-5",
          type: "chapter",
          number: "5",
          title: gettext("privacy_section_2_chapter_5_title"),
          content: gettext("privacy_section_2_chapter_5_content")
        },
        %{
          id: "chapter-6",
          type: "chapter",
          number: "6",
          title: gettext("privacy_section_2_chapter_6_title"),
          content: gettext("privacy_section_2_chapter_6_content")
        }
      ]
      3 -> [
        %{
          id: "chapter-12",
          type: "chapter",
          number: "12",
          title: gettext("privacy_section_3_chapter_12_title"),
          content: gettext("privacy_section_3_chapter_12_content")
        },
        %{
          id: "chapter-13",
          type: "chapter",
          number: "13",
          title: gettext("privacy_section_3_chapter_13_title"),
          content: gettext("privacy_section_3_chapter_13_content")
        }
      ]
      _ -> []
    end
  end
end
