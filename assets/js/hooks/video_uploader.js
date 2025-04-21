// Hook to preview selected videos as playable elements
const VideoUploader = {
  mounted() {
    // Determine the file input element
    const input =
      this.el.tagName === 'INPUT'
        ? this.el
        : this.el.querySelector('input[type="file"]');
    if (!input) return;

    // Create a container for video previews
    const previewContainer = document.createElement('div');
    previewContainer.className = 'video-previews grid grid-cols-2 gap-4 mb-4';
    this.el.prepend(previewContainer);

    // Listen for file selection and render video previews
    input.addEventListener('change', (event) => {
      previewContainer.innerHTML = '';
      const files = Array.from(event.target.files);
      files.forEach((file) => {
        const videoEl = document.createElement('video');
        videoEl.controls = true;
        videoEl.className = 'w-full h-40 rounded';
        videoEl.src = URL.createObjectURL(file);
        previewContainer.appendChild(videoEl);
      });
    });
  }
};

export default VideoUploader;
