// Chunked file upload with IndexedDB resume, previews, and SNS trigger
// This is a Phoenix LiveView JS hook, but works with plain JS as well

// Custom modal dialog for unsaved uploads
import { showSaveLeaveDialog } from "../components/SaveLeaveDialog";


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

// --- IndexedDB helpers for full file persistence ---
async function saveFilesToIndexedDB(files) {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, 'readwrite');
  for (const file of files) {
    const fileId = getFileId(file);
    const metadata = {
      fileId,
      name: file.name,
      size: file.size,
      lastModified: file.lastModified,
      type: file.type,
      previewUrl: URL.createObjectURL(file),
      fileBlob: file
    };
    tx.objectStore(STORE_NAME).put(metadata);
  }
  return tx.complete;
}

async function loadFilesFromIndexedDB() {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, 'readonly');
  const store = tx.objectStore(STORE_NAME);
  return new Promise((resolve) => {
    const files = [];
    store.openCursor().onsuccess = (event) => {
      const cursor = event.target.result;
      if (cursor) {
        files.push(cursor.value);
        cursor.continue();
      } else {
        resolve(files);
      }
    };
  });
}

async function clearAllFilesFromIndexedDB() {
  const db = await openDB();
  const tx = db.transaction(STORE_NAME, 'readwrite');
  tx.objectStore(STORE_NAME).clear();
  return tx.complete;
}

function isDashboardInternalLink(href) {
  // Adjust this logic to match your dashboard tab URLs
  // Example: all dashboard tabs start with '/dashboard'
  try {
    const url = new URL(href, window.location.origin);
    return url.pathname.startsWith('/dashboard');
  } catch {
    return false;
  }
}



const FileUploader = {
  async mounted() {
    this.input = this.el.querySelector('input[type="file"]');
    this.inputContainer = this.el.querySelector('#file-input-container');
    this.preview = this.el.querySelector('.preview');
    this.fileCountDisplay = document.getElementById('file-count-figure');
    if (this.fileCountDisplay) {
      this.fileCountFig = this.fileCountDisplay.querySelector('div');
      this.fileCountCaption = this.fileCountDisplay.querySelector('figcaption');
    }
    // Use the overlay reset button in the DOM

    this.input.addEventListener('change', (e) => this.handleFiles(e.target.files));

    // On mount, always check persistent storage for files and hide input if needed
    setTimeout(() => {
      loadFilesFromIndexedDB().then((persistedFiles) => {
        if (this.inputContainer) {
          if (persistedFiles && persistedFiles.length > 0) {
            this.inputContainer.style.display = 'none';
          } else {
            this.inputContainer.style.display = 'flex';
          }
        }
      });
    }, 50);

    // Intercept navigation away from dashboard (not tab switches)
    this._navHandler = (e) => {
      // Only handle anchor clicks
      let anchor = e.target.closest('a');
      if (!anchor || !anchor.href) return;
      // Ignore dashboard-internal tab switches
      if (isDashboardInternalLink(anchor.href)) return;
      // If no files, allow navigation
      if (!this.files || this.files.length === 0) return;
      // Show confirmation dialog
      e.preventDefault();
      showSaveLeaveDialog({
        onLeave: async () => {
          // Discard files and clear storage, then navigate
          this.files = [];
          await clearAllFilesFromIndexedDB();
          window.location.href = anchor.href;
        },
        onSaveAndLeave: async () => {
          // Persist files for resume, then navigate
          await saveFilesToIndexedDB(this.files);
          window.location.href = anchor.href;
        }
      });
    };
    document.addEventListener('click', this._navHandler, true);

    // Also handle browser navigation (back/forward/refresh)
    this._beforeUnloadHandler = (e) => {
      if (this.files && this.files.length > 0) {
        e.preventDefault();
        e.returnValue = '';
        return '';
      }
    };
    window.addEventListener('beforeunload', this._beforeUnloadHandler);

    this.files = [];
    this.currentIndex = 0;
    this.progress = {};
    // Restore files from IndexedDB on mount
    const savedFiles = await loadFilesFromIndexedDB();
    if (savedFiles.length > 0) {
      this.files = savedFiles.map(f => {
        try {
          const file = new File([f.fileBlob], f.name, {
            type: f.type,
            lastModified: f.lastModified,
          });
          file.previewUrl = f.previewUrl;
          return file;
        } catch {
          f.fileBlob.previewUrl = f.previewUrl;
          return f.fileBlob;
        }
      });
      this.renderPreview();
      if (this.inputContainer) this.inputContainer.style.display = 'none';
      if (this.fileCountDisplay && this.fileCountFig && this.fileCountCaption) {
        this.fileCountFig.textContent = `${this.files.length}`;
        this.fileCountCaption.textContent = this.files.length === 1
          ? '1 file selected'
          : `${this.files.length} files selected`;
        this.fileCountDisplay.style.display = 'flex';
        // Notify LiveView of restored files
        this.pushEventTo(this.el, "file_selected", { count: this.files.length });
      } else {
        if (this.inputContainer) this.inputContainer.style.display = 'flex';
      }
    } else {
      if (this.inputContainer) this.inputContainer.style.display = 'flex';
    }
    this.renderResumeList();
  },
  async handleFiles(fileList) {
    this.files = Array.from(fileList);
    this.currentIndex = 0;
    // Notify LiveView that files are selected
    this.pushEventTo(this.el, "file_selected", { count: this.files.length });
    await saveFilesToIndexedDB(this.files);
    this.renderPreview();
    if (this.fileCountDisplay && this.fileCountFig && this.fileCountCaption) {
      this.fileCountFig.textContent = `${this.files.length}`;
      this.fileCountCaption.textContent = this.files.length === 1
        ? '1 file selected'
        : `${this.files.length} files selected`;
      this.fileCountDisplay.style.display = 'flex';
    }
    // Hide file input and upload button after selection
    if (this.inputContainer) {
      this.inputContainer.style.display = 'none';
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
    wrapper.className = 'flex justify-center items-center relative min-w-[320px] max-w-[480px] w-full overflow-hidden';
    // Add delete button (top right of preview)
    const deleteBtn = document.createElement('button');
    deleteBtn.type = 'button'; // Prevent form submission/navigation
    deleteBtn.textContent = '✕';
    deleteBtn.title = 'Remove this file';
    deleteBtn.className = 'absolute top-2 right-2 z-20 bg-red-500 text-white rounded-full px-2 py-1 shadow hover:bg-red-600 transition';
    deleteBtn.onclick = async (e) => {
      e.stopPropagation();
      // Remove file at currentIndex
      const removedFile = this.files[this.currentIndex];
      this.files.splice(this.currentIndex, 1);
      // Remove from IndexedDB (progress store)
      if (removedFile) {
        const fileId = getFileId(removedFile);
        await deleteProgress(fileId);
      }
      await saveFilesToIndexedDB(this.files);
      if (this.currentIndex >= this.files.length) {
        this.currentIndex = Math.max(0, this.files.length - 1);
      }
      this.renderPreview();
      // Show file input if all files gone
      if (this.files.length === 0) {
        if (this.inputContainer) this.inputContainer.style.display = 'flex';
      }
      // Notify LiveView about updated file count
      this.pushEventTo(this.el, "file_selected", { count: this.files.length });
    };
    wrapper.appendChild(deleteBtn);
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

  async resetUpload() {
    await clearAllFilesFromIndexedDB();
    this.files = [];
    this.currentIndex = 0;
    this.renderPreview();
    if (this.fileCountDisplay && this.fileCountFig && this.fileCountCaption) {
      this.fileCountFig.textContent = '';
      this.fileCountCaption.textContent = '';
      this.fileCountDisplay.style.display = 'none';
    }
    if (this.input) {
      this.input.value = '';
    }
    if (this.uploadBtn) {
      this.uploadBtn.style.display = 'inline-block';
    }

    if (this.inputContainer) {
      this.inputContainer.style.display = 'flex';
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
