// Chunked file upload with IndexedDB resume, previews, and SNS trigger
// This is a Phoenix LiveView JS hook, but works with plain JS as well

const CHUNK_SIZE = 1024 * 1024 * 2; // 2MB
const DB_NAME = 'chunked_uploads';
const STORE_NAME = 'progress';

function openDB() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, 1);
    req.onupgradeneeded = () => {
      req.result.createObjectStore(STORE_NAME, { keyPath: 'fileId' });
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}
async function saveProgress(fileId, data) {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, 'readwrite');
  tx.objectStore(STORE_NAME).put({ fileId, ...data });
  return tx.complete;
}
async function getProgress(fileId) {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, 'readonly');
  return new Promise((res) => {
    tx.objectStore(STORE_NAME).get(fileId).onsuccess = (e) => res(e.target.result);
  });
}
async function deleteProgress(fileId) {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, 'readwrite');
  tx.objectStore(STORE_NAME).delete(fileId);
  return tx.complete;
}

function getFileId(file) {
  // Use a hash of name+size+lastModified for uniqueness
  return (
    file.name + '-' + file.size + '-' + file.lastModified
  ).replace(/[^a-zA-Z0-9_-]/g, '');
}

const FileUploader = {
  mounted() {
    this.input = this.el.querySelector('input[type="file"]');
    this.inputContainer = this.el.querySelector('#file-input-container');
    this.preview = this.el.querySelector('.preview');
    this.snsSelect = this.el.querySelector('.sns-select');
    this.uploadBtn = this.el.querySelector('.upload-btn');
    // Use the static file count figure in the DOM
    this.fileCountDisplay = document.getElementById('file-count-figure');
    if (this.fileCountDisplay) {
      this.fileCountFig = this.fileCountDisplay.querySelector('div');
      this.fileCountCaption = this.fileCountDisplay.querySelector('figcaption');
    }

    // Create and insert reset button
    this.resetBtn = document.createElement('button');
    this.resetBtn.textContent = 'Reset';
    this.resetBtn.className = 'reset-btn inline-flex items-center px-3 py-1 bg-gray-200 text-gray-700 rounded hover:bg-gray-300 ml-2 mb-2 hidden';
    this.resetBtn.onclick = () => this.resetUpload();
    this.preview.parentNode.insertBefore(this.resetBtn, this.fileCountDisplay.nextSibling);
    this.input.addEventListener('change', (e) => this.handleFiles(e.target.files));
    this.uploadBtn.addEventListener('click', () => this.startUpload());
    this.files = [];
    this.currentIndex = 0;
    this.progress = {};
    this.renderResumeList();
  },
  async handleFiles(fileList) {
    this.files = Array.from(fileList);
    this.currentIndex = 0;
    this.renderPreview();
    // Show file count
    if (this.fileCountDisplay && this.fileCountFig && this.fileCountCaption) {
      this.fileCountFig.textContent = `${this.files.length}`;
      this.fileCountCaption.textContent = this.files.length === 1
        ? '1 file selected'
        : `${this.files.length} files selected`;
      this.fileCountDisplay.style.display = 'flex';
    }
    // Show reset button
    if (this.resetBtn) {
      this.resetBtn.style.display = 'inline-block';
    }
    // Hide file input and upload button after selection
    if (this.inputContainer) {
      this.inputContainer.style.display = 'none';
    }
    if (this.uploadBtn) {
      this.uploadBtn.style.display = 'none';
    }
  },

  renderPreview() {
    this.preview.innerHTML = '';
    if (this.files.length === 0) {
      if (this.fileCountDisplay) this.fileCountDisplay.textContent = '';
      return;
    }
    const file = this.files[this.currentIndex];
    const url = URL.createObjectURL(file);

    // Create main flex container
    const flexRow = document.createElement('div');
    flexRow.className = 'flex flex-row items-center justify-center w-full';

    // Left button
    if (this.files.length > 1) {
      const leftBtn = document.createElement('button');
      leftBtn.textContent = '<';
      leftBtn.className = 'mx-2 bg-white bg-opacity-70 rounded-full px-3 py-2 shadow hover:bg-indigo-100 z-10 text-2xl font-bold flex-shrink-0';
      leftBtn.style.height = '56px';
      leftBtn.onclick = () => {
        this.currentIndex = (this.currentIndex - 1 + this.files.length) % this.files.length;
        this.renderPreview();
      };
      flexRow.appendChild(leftBtn);
    }

    // Aspect-ratio box
    const wrapper = document.createElement('div');
    wrapper.className = 'aspect-w-16 aspect-h-9 flex justify-center items-center relative min-w-[320px] max-w-[480px] w-full';
    let el;
    if (file.type.startsWith('video')) {
      el = document.createElement('video');
      el.controls = true;
      el.className = 'rounded shadow max-h-72 max-w-full';
    } else {
      el = document.createElement('img');
      el.className = 'rounded shadow max-h-72 max-w-full object-contain';
    }
    el.src = url;
    wrapper.appendChild(el);
    flexRow.appendChild(wrapper);

    // Right button
    if (this.files.length > 1) {
      const rightBtn = document.createElement('button');
      rightBtn.textContent = '>';
      rightBtn.className = 'mx-2 bg-white bg-opacity-70 rounded-full px-3 py-2 shadow hover:bg-indigo-100 z-10 text-2xl font-bold flex-shrink-0';
      rightBtn.style.height = '56px';
      rightBtn.onclick = () => {
        this.currentIndex = (this.currentIndex + 1) % this.files.length;
        this.renderPreview();
      };
      flexRow.appendChild(rightBtn);
    }

    this.preview.appendChild(flexRow);
    // Update file count display
    if (this.fileCountDisplay && this.fileCountFig && this.fileCountCaption) {
      this.fileCountFig.textContent = `${this.files.length}`;
      this.fileCountCaption.textContent = this.files.length === 1
        ? '1 file selected'
        : `${this.files.length} files selected (showing ${this.currentIndex + 1} of ${this.files.length})`;
      this.fileCountDisplay.style.display = 'flex';
    }
  },

  resetUpload() {
    // Reset file input
    this.files = [];
    this.currentIndex = 0;
    this.preview.innerHTML = '';
    if (this.input) {
      this.input.value = '';
    }
    if (this.inputContainer) {
      this.inputContainer.style.display = 'block';
    }
    if (this.uploadBtn) {
      this.uploadBtn.style.display = 'inline-block';
    }
    if (this.fileCountDisplay && this.fileCountFig && this.fileCountCaption) {
      this.fileCountFig.textContent = '';
      this.fileCountCaption.textContent = '';
      this.fileCountDisplay.style.display = 'none';
    }
    if (this.resetBtn) {
      this.resetBtn.style.display = 'none';
    }
  },
  async startUpload() {
    for (const file of this.files) {
      await this.uploadFile(file);
    }
    // Hide file input after upload
    if (this.input) {
      this.input.style.display = 'none';
    }
  },
  async uploadFile(file) {
    const fileId = getFileId(file);
    let uploaded = 0;
    const saved = await getProgress(fileId);
    if (saved) uploaded = saved.bytesUploaded;
    // Ask server which chunks are present (for true resume)
    const status = await fetch(`/api/upload_status/${fileId}`).then(r => r.json());
    if (status && status.bytesUploaded) uploaded = Math.max(uploaded, status.bytesUploaded);
    for (let start = uploaded; start < file.size; start += CHUNK_SIZE) {
      const chunk = file.slice(start, start + CHUNK_SIZE);
      const form = new FormData();
      form.append('chunk', chunk);
      form.append('fileId', fileId);
      form.append('fileName', file.name);
      form.append('start', start);
      form.append('total', file.size);
      const resp = await fetch('/api/upload_chunk', { method: 'POST', body: form });
      if (!resp.ok) throw new Error('Chunk upload failed');
      await saveProgress(fileId, { fileName: file.name, bytesUploaded: start + chunk.size });
    }
    await fetch('/api/complete_upload', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fileId, fileName: file.name })
    });
    await deleteProgress(fileId);
    // SNS trigger
    const sns = this.snsSelect.value;
    if (sns) {
      await fetch('/api/sns_post', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ fileId, sns })
      });
    }
    alert('Upload complete: ' + file.name);
  },
  async renderResumeList() {
    // On mount, show incomplete uploads to resume
    const db = await openDB();
    const tx = db.transaction(STORE_NAME, 'readonly');
    const req = tx.objectStore(STORE_NAME).getAll();
    req.onsuccess = () => {
      const list = this.el.querySelector('.resume-list');
      if (!list) return;
      list.innerHTML = '';
      req.result.forEach(item => {
        const li = document.createElement('li');
        li.textContent = `${item.fileName} (${item.bytesUploaded} bytes uploaded)`;
        const btn = document.createElement('button');
        btn.textContent = 'Resume';
        btn.onclick = () => {
          // Simulate file selection and upload
          alert('Please re-select the file to resume upload.');
        };
        li.appendChild(btn);
        list.appendChild(li);
      });
    };
  }
};

export default FileUploader;
