# File Server Implementation Plan

## Overview
Brief description of the feature and its purpose.

## Implementation Details
- Core implementation: `lib/myapp/file_server.ex`
- Dependencies
- Technical specifications

## Task Breakdown

### 1. Implement FileServer module (lib/myapp/file_server.ex)

- Basic file operations
  - Read file `read_file/1`
  - Write file `write_file/2`
  - Check if file exists `file_exists?/1`
  - Delete file `delete_file/1`

- Built-in logging
  - Success and error cases are logged into terminal using Elixir's `Logger`
  - Detailed error messages for debugging

- Proper error handling
  - All functions return tagged tuples (`{:ok, result}` or `{:error, reason}`)
  - Consistent error handling patterns throughout

- Usage example in `file_server.ex`
  ```elixir
  Myapp.FileServer.write_file("path/to/file", "content")
  Myapp.FileServer.read_file("path/to/file")
  ```

### 2. Implement FileController module (lib/myapp_web/controllers/file_controller.ex)

- Add `file_controller.ex` 
  - Upload file `upload/2`
    - `path` and `filename` are extracted from the request
    - api must be return the `status` and `message` of the request as a JSON object
    - Return `422 Unprocessable Entity` if file upload fails
    - Use `inspect/1` to log error messages more clearly

  - Download file `download/2`
    - Set content type to `application/octet-stream` (generic binary file type)
    - Set `Content-Disposition` header:
      - `attachment` and suggest filename to download instead of displaying
      - `filename=#{filename}` to suggest the filename for the downloaded file
      - use `~s()` sigil to interpolate string
    - Send file content with `200` status
    - Return `404 Not Found` if file not found

  - Implement `upload_path/1` to return the path to the uploaded file
    - Go to `priv/static/uploads` by default
    - Add `priv/static/uploads` to `.gitignore`
  
- Adjust `router.ex` to include `file_controller` routes

### 3. Implement LiveView component for uploading and downloading files (lib/myapp_web/live/)

- Create `file_live.ex` and `file_live.html.heex` files

- `FileLive` module handles file uploads and downloads
  - File uploads with drag-and-drop support
  - File listing
  - File deletion
  - Error handling

- Template for `file_live.html.heex` is provided
  - A drag-and-drop upload zone
  - Progress indicators for uploads
  - A list of uploaded files with download and delete buttons
  - Responsive design using Tailwind CSS classes

- Usage example in `file_live.html.heex`
  - Access to `localhost:4000/files`

## Integration Plan
How this feature will be integrated into the existing system.

### 1. AWS S3 Integration
- Add dependencies into `mix.exs`
  - Add `aws` to `deps` for common AWS functionality
  - Add `hackney` to `deps` for HTTP requests (for `aws`)
- Run `mix deps.get`
- [ ] Create bucket
- [ ] Upload file
- [ ] Download file

## Testing Requirements
- Unit tests
- Integration tests
- Validation criteria

## Timeline
- Estimated start date
- Major milestones
- Target completion date

