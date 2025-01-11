defmodule MyappWeb.PrivacyPolicyLocalizer do
  import MyappWeb.Gettext

  def localize_privacy_policy do
    %{
      "privacyPolicy" => %{
        "title" => gettext("Privacy Policy"),
        "effectiveDate" => "YYYY-MM-DD",
        "introduction" => gettext("This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website."),
        "informationCollection" => %{
          "personalData" => gettext("We may collect personal data such as your name, email address, and phone number."),
          "usageData" => gettext("We may collect information about your interactions with our website, such as your IP address, browser type, and pages visited.")
        },
        "useOfInformation" => %{
          "serviceProvision" => gettext("We use the information we collect to provide, maintain, and improve our services."),
          "communication" => gettext("We may use your information to communicate with you about updates, promotions, and other information.")
        },
        "informationSharing" => %{
          "thirdParties" => gettext("We do not share your personal information with third parties except as described in this policy."),
          "legalRequirements" => gettext("We may disclose your information if required to do so by law or in response to valid requests by public authorities.")
        },
        "dataSecurity" => gettext("We implement appropriate security measures to protect your information from unauthorized access, alteration, disclosure, or destruction."),
        "yourRights" => %{
          "access" => gettext("You have the right to access the personal information we hold about you."),
          "correction" => gettext("You have the right to request the correction of inaccurate personal information."),
          "deletion" => gettext("You have the right to request the deletion of your personal information.")
        },
        "changesToPolicy" => gettext("We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on our website."),
        "contactInformation" => %{
          "email" => gettext("contact@example.com"),
          "phone" => gettext("+1-234-567-890")
        }
      }
    }
  end
end
