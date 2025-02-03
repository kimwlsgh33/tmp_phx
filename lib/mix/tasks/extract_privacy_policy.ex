defmodule Mix.Tasks.ExtractPrivacyPolicy do
  use Mix.Task
  
  @shortdoc "Extracts translatable strings from privacy policy JSON"
  
  def run(_) do
    Mix.Task.run("app.start")
    
    json_path = Application.app_dir(:myapp, "priv/privacy_policy/v1.json")
    {:ok, content} = File.read(json_path)
    {:ok, policy} = Jason.decode(content)
    
    document = policy["document"]
    
    # Extract strings and create PO entries
    entries = []
    |> extract_index_entries(document["index"])
    |> extract_section_entries(document["sections"])
    
    # Write to POT file
    pot_path = Application.app_dir(:myapp, "priv/gettext/privacy_policy.pot")
    pot_content = generate_pot_content(entries)
    File.write!(pot_path, pot_content)
    
    # Generate PO files for each locale
    ["en", "ko"]
    |> Enum.each(fn locale ->
      po_dir = Application.app_dir(:myapp, "priv/gettext/#{locale}/LC_MESSAGES")
      po_path = Path.join(po_dir, "privacy_policy.po")
      
      unless File.exists?(po_path) do
        File.mkdir_p!(po_dir)
        File.write!(po_path, pot_content)
      end
    end)
    
    Mix.shell().info("Privacy policy translations extracted successfully!")
  end
  
  defp extract_index_entries(entries, %{"items" => items} = index) do
    entries
    |> add_entry(index["title"])
    |> add_entry(index["subtitle"])
    |> Enum.reduce(entries, fn item, acc ->
      add_entry(acc, item["title"])
    end)
  end
  
  defp extract_section_entries(entries, sections) when is_list(sections) do
    Enum.reduce(sections, entries, fn section, acc ->
      acc
      |> add_entry(section["title"])
      |> extract_chapter_entries(section["chapters"])
    end)
  end
  
  defp extract_chapter_entries(entries, chapters) when is_list(chapters) do
    Enum.reduce(chapters, entries, fn chapter, acc ->
      acc = add_entry(acc, chapter["title"])
      
      case chapter["content"] do
        content when is_list(content) ->
          Enum.reduce(content, acc, fn item, inner_acc ->
            add_entry(inner_acc, item["text"])
          end)
        _ -> acc
      end
    end)
  end
  
  defp add_entry(entries, text) when is_binary(text) do
    [%{msgid: text, msgstr: "", comments: ["privacy_policy"]} | entries]
  end
  
  defp add_entry(entries, _), do: entries
  
  defp generate_pot_content(entries) do
    header = ~s"""
    ## This file is a PO Template file.
    ##
    ## "msgid"s here are often extracted from source code.
    ## Add new translations manually only if they're dynamic
    ## translations that can't be statically extracted.
    ##
    ## Run "mix gettext.extract" to bring this file up to
    ## date. Leave "msgstr"s empty as changing them here has no
    ## effect: edit them in PO (.po) files instead.
    msgid ""
    msgstr ""
    "Project-Id-Version: \\n"
    "POT-Creation-Date: \\n"
    "PO-Revision-Date: \\n"
    "Last-Translator: \\n"
    "Language-Team: \\n"
    "MIME-Version: 1.0\\n"
    "Content-Type: text/plain; charset=UTF-8\\n"
    "Content-Transfer-Encoding: 8bit\\n"
    "X-Generator: mix gettext.extract\\n"
    """
    
    entries_content = Enum.map_join(entries, "\n\n", fn entry ->
      comments = Enum.map_join(entry.comments, "\n", &"#: #{&1}")
      """
      #{comments}
      msgid "#{String.replace(entry.msgid, "\"", "\\\"")}"
      msgstr "#{entry.msgstr}"
      """
    end)
    
    header <> "\n\n" <> entries_content
  end
end
