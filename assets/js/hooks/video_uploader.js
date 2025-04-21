import localforage from "localforage";
import { FFmpeg } from "@ffmpeg/ffmpeg";

const ffmpeg = new FFmpeg();
ffmpeg.on("log", console.log);

const VideoUploader = {
  mounted() {
    console.log("VideoUploader mounted", this.el);
    const input = this.el.tagName === 'INPUT' ? this.el : this.el.querySelector('input[type="file"]');
    if (!input) {
      console.error('File input not found in VideoUploader container');
      return;
    }

    input.addEventListener("change", async (event) => {
      const file = event.target.files[0];
      if (!file) return;
      // Enforce 100MB limit
      if (file.size > 100 * 1024 * 1024) {
        alert("File exceeds 100MB limit");
        return;
      }

      // Notify UploadComponent that processing started
      this.pushEventTo(this.el, "processing", { filename: file.name, size: file.size });

      // Load FFmpeg core
      if (!ffmpeg.loaded) {
        await ffmpeg.load();
      }

      const name = file.name;
      // Write the selected file into FFmpeg’s virtual FS
      const buffer = await file.arrayBuffer();
      await ffmpeg.writeFile(name, new Uint8Array(buffer));

      // Report compression progress
      ffmpeg.on("progress", ({ ratio }) => {
        const pct = Math.floor(ratio * 100);
        // Report progress to UploadComponent
        this.pushEventTo(this.el, "upload-progress", { pct });
      });

      // Execute the FFmpeg command
      await ffmpeg.exec([
        "-i", name,
        "-vcodec", "libx264",
        "-crf", "23",
        "output.mp4"
      ]);

      // Read the compressed file back out
      const data = await ffmpeg.readFile("output.mp4");
      const blob = new Blob([data.buffer], { type: "video/mp4" });

      const key = `video-${Date.now()}`;
      await localforage.setItem(key, blob);

      const url = URL.createObjectURL(blob);
      // Notify UploadComponent that upload is complete
      this.pushEventTo(this.el, "client_upload_complete", { url, key });
    });
  }
};

export default VideoUploader;
