const VideoPreview = {
  mounted() {
    console.log("VideoPreview mounted", this.el);

    // 파일 입력 요소 찾기
    const fileInput = this.el.querySelector('input[type="file"]');
    if (!fileInput) {
      console.error('File input not found in VideoPreview container');
      return;
    }

    // 파일 선택 이벤트 리스너 추가
    fileInput.addEventListener("change", (event) => {
      console.log("File selected", event.target.files);
      const file = event.target.files[0];
      if (!file) {
        return;
      }

      // 파일 정보 로깅
      console.log("File info:", file.name, file.size, file.type);
    });
  },

  updated() {
    console.log("VideoPreview updated", this.el.dataset);
    const tempVideoUrl = this.el.dataset.tempVideoUrl;
    if (tempVideoUrl) {
      console.log("Temp video URL updated:", tempVideoUrl);
    }
  }
};

const VideoPlayer = {
  mounted() {
    console.log("VideoPlayer mounted", this.el);
    const video = this.el;

    // 오류 이벤트 리스너 추가
    video.addEventListener("error", (e) => {
      console.error(`Video playback error:`, e);
    });

    // 비디오 로드 이벤트 리스너 추가
    video.addEventListener("loadeddata", () => {
      console.log("Video loaded successfully", video.src);
      // 로드가 완료되면 자동 재생 시도
      if (video.autoplay) {
        video.play().catch(err => {
          console.warn("Autoplay failed:", err);
        });
      }
    });

    // 이벤트 리스너 추가 - 비디오 업로드 완료 시
    this.handleEvent("video-uploaded", ({ url }) => {
      console.log("Video uploaded event received", url);
      if (video.src !== url) {
        video.src = url;
        video.load();
      }
    });
  },

  updated() {
    console.log("VideoPlayer updated", this.el);
    const video = this.el;

    // src가 변경되면 다시 로드
    if (video.src && video.paused) {
      video.load();
      // 자동 재생 시도
      setTimeout(() => {
        video.play().catch(err => {
          console.warn("Autoplay failed on update:", err);
        });
      }, 500);
    }
  }
};

export { VideoPreview, VideoPlayer };