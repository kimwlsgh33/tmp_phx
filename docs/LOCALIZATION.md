# Localization Strategy

## Overview
This document outlines the localization strategy for our Phoenix application, specifically focusing on the privacy policy content. We use Phoenix's built-in Gettext for internationalization (i18n) and localization (l10n).

## Directory Structure
```
priv/
├── gettext/
│   ├── default.pot
│   ├── privacy_policy.pot      # Privacy policy translations template
│   ├── errors.pot
│   ├── en/
│   │   └── LC_MESSAGES/
│   │       ├── errors.po
│   │       └── privacy_policy.po
│   └── ko/
│       └── LC_MESSAGES/
│           ├── errors.po
│           └── privacy_policy.po
└── privacy_policy/
    ├── v1.json
    ├── v2.json
    └── v2.md
```

## Implementation Plan

### 1. Privacy Policy Module
Create a dedicated module to handle privacy policy data and translations:
```elixir
# lib/myapp_web/privacy_policy.ex
defmodule MyappWeb.PrivacyPolicy do
  import MyappWeb.Gettext
  
  # Fetch section content with localization
  def get_section(section_id, locale \\ nil)
  
  # Fetch chapter content with localization
  defp get_chapters(section_number)
end
```

### 2. Controller Integration
Update the page controller to handle localization:
```elixir
# lib/myapp_web/controllers/page_controller.ex
defmodule MyappWeb.PageController do
  use MyappWeb, :controller
  
  def home(conn, _params) do
    locale = get_locale(conn)
    privacy_policy = MyappWeb.PrivacyPolicy.get_section("introduction", locale)
    render(conn, :home, privacy_policy: privacy_policy)
  end
end
```

### 3. Template Updates
Modify templates to use localized content:
```heex
# lib/myapp_web/controllers/page/page_html/home.html.heex
<div class="privacy-policy">
  <h1><%= gettext("privacy_policy_title") %></h1>
  <div class="introduction">
    <h2><%= @privacy_policy.title %></h2>
    <%= @privacy_policy.content %>
  </div>
</div>
```

### 4. Translation Files
Structure of translation files:

```pot
# priv/gettext/privacy_policy.pot
# Template for translations
msgid "privacy_policy_title"
msgstr ""
```

```po
# priv/gettext/ko/LC_MESSAGES/privacy_policy.po
msgid "privacy_policy_title"
msgstr "서비스 이용약관"
```

### 5. Language Switching
Add language switching functionality:
```elixir
# lib/myapp_web/controllers/locale_controller.ex
defmodule MyappWeb.LocaleController do
  use MyappWeb, :controller

  def set(conn, %{"locale" => locale}) do
    conn
    |> put_session(:locale, locale)
    |> redirect(to: ~p"/")
  end
end
```

## Implementation Steps

1. **Setup Translation Files**
   ```bash
   mix gettext.extract --merge
   mix gettext.merge priv/gettext --locale ko
   mix gettext.merge priv/gettext --locale en
   ```

2. **Create Modules**
   - Create `MyappWeb.PrivacyPolicy` module
   - Update `PageController`
   - Add `LocaleController`

3. **Update Templates**
   - Modify home template to use Gettext
   - Add language switcher component

4. **Convert Content**
   - Convert JSON content to translation keys
   - Add translations for each locale

## Best Practices

1. **Translation Keys**
   - Use descriptive, hierarchical keys (e.g., `privacy_section_1_title`)
   - Keep keys in English
   - Use lowercase with underscores

2. **Content Management**
   - Keep HTML/formatting separate from translations
   - Use interpolation for dynamic content
   - Document context for translators

3. **Testing**
   - Test with different locales
   - Verify fallback behavior
   - Check for missing translations

## Maintenance

1. **Adding New Languages**
   ```bash
   mix gettext.merge priv/gettext --locale [new_locale]
   ```

2. **Updating Translations**
   - Extract new translations: `mix gettext.extract`
   - Merge with existing files: `mix gettext.merge priv/gettext`

3. **Quality Checks**
   - Regularly check for missing translations
   - Validate formatting in different locales
   - Update documentation as needed

## Benefits

1. **Maintainability**
   - Clear separation of concerns
   - Easy to add new languages
   - Centralized translation management

2. **User Experience**
   - Consistent localization
   - Smooth language switching
   - Proper fallback handling

3. **Development**
   - Follows Phoenix conventions
   - Leverages built-in tools
   - Easy to extend and modify
