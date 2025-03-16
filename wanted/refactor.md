# Refactoring Plan: Step 1 - Eliminate OAuth Implementation Duplication

## Problem Description

Currently, the codebase contains significant duplication between the standalone OAuth implementation modules and their corresponding auth modules in the social media directory:

- Standalone OAuth modules: 
  - `lib/myapp/twitter_oauth.ex`
  - `lib/myapp/youtube_oauth.ex`
  - `lib/myapp/tiktok_oauth.ex`
  - `lib/myapp/instagram_oauth.ex`

- Corresponding auth modules:
  - `lib/myapp/social_media/auth/twitter.ex`
  - `lib/myapp/social_media/auth/youtube.ex`
  - `lib/myapp/social_media/auth/tiktok.ex`
  - `lib/myapp/social_media/auth/instagram.ex`

This duplication creates several issues:
1. Maintenance overhead - changes must be made in multiple places
2. Potential for inconsistencies between implementations
3. Confusion about which implementation should be used
4. Increased code complexity

## Files to Modify

1. Files to be removed:
   - `lib/myapp/twitter_oauth.ex`
   - `lib/myapp/youtube_oauth.ex`
   - `lib/myapp/tiktok_oauth.ex`
   - `lib/myapp/instagram_oauth.ex`

2. Files to be enhanced:
   - `lib/myapp/social_media/auth/twitter.ex`
   - `lib/myapp/social_media/auth/youtube.ex`
   - `lib/myapp/social_media/auth/tiktok.ex`
   - `lib/myapp/social_media/auth/instagram.ex`

3. Files that may need updates for imports/references:
   - Any controllers or services that currently reference the standalone OAuth modules

## Specific Changes Needed

1. For each social media platform:
   - Identify any unique functionality in the standalone OAuth module not present in the auth module
   - Merge this functionality into the corresponding auth module
   - Ensure consistent naming conventions and patterns across all auth modules
   - Update any references to the standalone modules to point to the auth modules

2. Configuration standardization:
   - Move all configuration retrieval to use the `SocialMediaConfig` module
   - Replace direct `Application.get_env` and `System.get_env` calls

3. Update imports and references:
   - Find all references to the standalone OAuth modules
   - Update them to use the consolidated auth modules
   - Update function calls as needed to match the consolidated interface

## Risks and Considerations

1. **Backward Compatibility**: Removing modules and changing APIs may break existing functionality.
   - Mitigation: Thoroughly identify all usage of the current modules before removal.
   - Consider creating adapter functions in the auth modules that match the old API signatures.

2. **Testing Gaps**: Existing tests may be insufficient to validate the refactored code.
   - Mitigation: Ensure comprehensive test coverage before and after the refactoring.
   - Add tests for any edge cases uncovered during the refactoring.

3. **Configuration Issues**: Different approaches to configuration may cause runtime errors.
   - Mitigation: Test in all environments (dev, test, prod) to ensure config is properly accessed.

4. **Auth Flow Disruption**: OAuth flows are critical authentication paths that must not be broken.
   - Mitigation: Manual testing of complete auth flows for each provider after refactoring.

5. **Deployment Considerations**: 
   - Consider whether a phased approach is needed (first deprecate old modules, then remove).
   - Plan for a rollback strategy if issues are discovered post-deployment.

## Implementation Approach

1. Start with one provider (e.g., Twitter) as a template for the others.
2. For each provider:
   - Create a feature branch
   - Implement changes
   - Write tests
   - Verify functionality
   - Submit for review
3. After all providers are refactored individually, perform integration testing of the entire system.

1. Refactor OAuth Implementation Duplication
•  Currently, there's significant duplication between the OAuth implementations (twitter_oauth.ex, youtube_oauth.ex, tiktok_oauth.ex, instagram_oauth.ex) and their corresponding auth modules in social_media/auth/.
•  Action: Remove the standalone OAuth modules and consolidate the functionality into the SocialAuth implementations.
•  Reason: Follows rule "Check if the feature already exists (duplications)" and "Remove the duplication".
2. Standardize Configuration Management
•  Current issues:
◦  Twitter uses Application.get_env
◦  YouTube uses System.get_env directly
◦  TikTok uses a mix of both
◦  Instagram uses System.get_env
•  Action: Move all configuration to SocialMediaConfig module, which TikTok already uses.
•  This follows the TODO comments in twitter_oauth.ex: "Move configuration retrieval to SocialMediaConfig module"
3. Standardize Error Handling
•  Current state: Each module handles errors differently
•  Action: Create a consistent error handling pattern across all social media integrations
•  Implementation:
◦  Standardize error tuples
◦  Use consistent logging patterns
◦  Create shared error types
4. Clean Up Debug Code
•  Remove debug IO.inspect calls from instagram_oauth.ex
•  These are development artifacts that shouldn't be in production code
5. Consolidate Token Management
•  Current state: Token storage and retrieval logic is duplicated across modules
•  Action: Create a unified token management system
•  Move common token operations to a shared module
6. Implement Consistent HTTP Client Usage
•  Current state: Mixed usage of HTTPoison and custom HttpClient
•  Action: Standardize on HttpClient for all HTTP requests
•  This will make it easier to manage and monitor API calls
7. Standardize OAuth2 Flow Implementation
•  Current state: Different approaches to OAuth2 flow between providers
•  Action: Create a consistent OAuth2 implementation pattern
•  Use the behavior-based approach consistently across all providers

For each change, we should:
1. Check syntax of the features
2. Check logic of the features
3. Check error handling of the features

Would you like me to start implementing any specific part of this plan?
