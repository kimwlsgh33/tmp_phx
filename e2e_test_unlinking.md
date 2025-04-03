# End-to-End Testing of Account Unlinking Functionality

This document provides manual testing steps to verify the updated account unlinking functionality, which now removes both the primary->linked and linked->primary relationships.

## Prerequisites

- A running development environment
- Access to the application database (via `psql`, `iex`, or another database client)
- Admin privileges to view database records

## Test Scenario 1: Verify Unlinking Removes Both Relationship Directions

### Setup

1. Create two test user accounts (or use existing accounts):
   - User A (will be the primary user)
   - User B (will be the linked user)

2. Record the user IDs for reference:
   ```
   User A ID: _________________
   User B ID: _________________
   ```

### Test Steps

1. **Link the accounts:**
   - Sign in as User A
   - Navigate to account settings or user profile
   - Use the link account feature to link User B to User A
   - Confirm the accounts are successfully linked

2. **Verify database state after linking:**
   - Open a database console and run:
   ```sql
   SELECT * FROM linked_accounts WHERE primary_user_id = 'User_A_ID';
   SELECT * FROM linked_accounts WHERE primary_user_id = 'User_B_ID';
   ```
   - Confirm a record exists showing User A linked to User B
   - Note if there's also a reciprocal link from User B to User A

3. **Perform the unlinking:**
   - While signed in as User A, navigate to the linked accounts section
   - Unlink User B's account
   - Alternatively, sign in as User B and sign out/log out

4. **Verify database state after unlinking:**
   - Open a database console and run:
   ```sql
   SELECT * FROM linked_accounts WHERE primary_user_id = 'User_A_ID';
   SELECT * FROM linked_accounts WHERE primary_user_id = 'User_B_ID';
   ```
   - Confirm that both directions of the link have been removed:
     - User A should no longer have User B as a linked account
     - User B should no longer have User A as a linked account

5. **Verify application behavior:**
   - Sign out of all accounts
   - Sign in as User A and verify User B is not shown as a linked account
   - Sign out, then sign in as User B and verify User A is not shown as a linked account

## Test Scenario 2: One-Way Link Removal

### Setup

1. Manually create a one-way link in the database:
   ```sql
   INSERT INTO linked_accounts (primary_user_id, linked_user_id) VALUES ('User_A_ID', 'User_B_ID');
   ```

2. **Perform the unlinking:**
   - While signed in as User A, navigate to the linked accounts section
   - Unlink User B's account

3. **Verify database state after unlinking:**
   - Open a database console and run:
   ```sql
   SELECT * FROM linked_accounts WHERE primary_user_id = 'User_A_ID';
   SELECT * FROM linked_accounts WHERE primary_user_id = 'User_B_ID';
   ```
   - Confirm that no link records exist for either user

## Test Scenario 3: Using IEx to Verify Unlinking Function

You can also test the unlinking function directly through an IEx session:

1. Start an IEx session with the application:
   ```bash
   iex -S mix
   ```

2. Create a test link:
   ```elixir
   primary_user_id = "User_A_ID" # Replace with actual ID
   linked_user_id = "User_B_ID"  # Replace with actual ID
   MyApp.Accounts.link_account(primary_user_id, linked_user_id)
   ```

3. Query the database to confirm the link was created:
   ```elixir
   MyApp.Repo.all(MyApp.Accounts.LinkedAccount)
   ```

4. Unlink the account:
   ```elixir
   MyApp.Accounts.unlink_account(primary_user_id, linked_user_id)
   ```

5. Query the database again to confirm both links were removed:
   ```elixir
   MyApp.Repo.all(MyApp.Accounts.LinkedAccount)
   ```

## Test Results

Document your findings below:

- [ ] Unlinking successfully removes the primary->linked direction
- [ ] Unlinking successfully removes the linked->primary direction
- [ ] Application behavior correctly reflects the unlinked state
- [ ] Function returns success even when only one direction exists
- [ ] Function returns `:not_found` when neither link exists

## Notes

- If you find any issues or unexpected behavior, please document them here.
- Include screenshots if applicable.

