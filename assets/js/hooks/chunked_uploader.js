// ChunkedUploader: Handles chunked upload, progress tracking in IndexedDB, resume, and SNS trigger
const ChunkedUploader = {
  mounted() {
    const input = this.el.querySelector('#chunked-upload-input');
    const progressDiv = this.el.querySelector('#chunked-upload-progress');
    const previewsDiv = this.el.querySelector('#chunked-upload-previews');
    if (!input) return;

    // Helper: Store/retrieve upload state in IndexedDB
    // (Simple wrapper, can be replaced with idb-keyval or similar)
    const dbName = 'upload-progress-v1';
    const storeName = 'uploads';
    function openDB() {
      return new Promise((resolve, reject) => {
        const req = indexedDB.open(dbName, 1);
        req.onupgradeneeded = () => {
          req.result.createObjectStore(storeName, { keyPath: 'fileId' });
        };
        req.onsuccess = () => resolve(req.result);
        req.onerror = reject;
      });
    }
    async function saveProgress(fileId, data) {
      const db = await openDB();
      const tx = db.transaction(storeName, 'readwrite');
      tx.objectStore(storeName).put({ fileId, ...data });
      return tx.complete;
    }
    async function getProgress(fileId) {
      const db = await openDB();
      const tx = db.transaction(storeName, 'readonly');
      return tx.objectStore(storeName).get(fileId);
    }
    async function deleteProgress(fileId) {
      const db = await openDB();
      const tx = db.transaction(storeName, 'readwrite');
      tx.objectStore(storeName).delete(fileId);
      return tx.complete;
    }

    // Chunk upload logic
    const CHUNK_SIZE = 1024 * 1024 * 2; // 2MB
    function getFileId(file) {
      // Simple hash: name+size+lastModified
      return (
        file.name + '-' + file.size + '-' + file.lastModified
      ).replace(/[^a-zA-Z0-9_-]/g, '');
    }

    async function uploadFile(file) {
      const fileId = getFileId(file);
      let uploadedBytes = 0;
      let uploadedChunks = [];
      // Check server for already uploaded chunks
      let resp = await fetch(`/api/upload/status/${fileId}`);
      if (resp.ok) {
        const { uploaded } = await resp.json();
        uploadedChunks = uploaded;
        uploadedBytes = Math.max(...uploadedChunks.map(c => c.end), 0);
      }
      // Resume from IndexedDB if present
      const local = await getProgress(fileId);
      if (local && local.bytesUploaded > uploadedBytes) {
        uploadedBytes = local.bytesUploaded;
      }
      // Upload chunks
      let offset = uploadedBytes;
      while (offset < file.size) {
        const chunk = file.slice(offset, offset + CHUNK_SIZE);
        const formData = new FormData();
        formData.append('fileId', fileId);
        formData.append('chunk', chunk);
        formData.append('offset', offset);
        formData.append('name', file.name);
        const res = await fetch('/api/upload/chunk', {
          method: 'POST',
          body: formData
        });
        if (!res.ok) {
          alert('Upload failed at offset ' + offset);
          break;
        }
        offset += CHUNK_SIZE;
        await saveProgress(fileId, {
          name: file.name,
          bytesUploaded: offset,
          size: file.size
        });
        renderProgress(fileId, file.name, offset, file.size);
      }
      // Finalize
      if (offset >= file.size) {
        await fetch(`/api/upload/complete/${fileId}`, { method: 'POST' });
        await deleteProgress(fileId);
        renderProgress(fileId, file.name, file.size, file.size, true);
        // Trigger SNS upload (user can select platforms in UI)
        fetch(`/api/upload/sns/${fileId}`, { method: 'POST' });
      }
    }

    // Render per-file progress
    function renderProgress(fileId, name, uploaded, total, done) {
      let el = document.getElementById('progress-' + fileId);
      if (!el) {
        el = document.createElement('div');
        el.id = 'progress-' + fileId;
        progressDiv.appendChild(el);
      }
      el.innerHTML = `<strong>${name}</strong>: ${Math.floor((uploaded/total)*100)}% ${done ? '✅' : ''}`;
    }

    // Render previews
    function renderPreview(file) {
      let el;
      if (file.type.startsWith('video')) {
        el = document.createElement('video');
        el.controls = true;
        el.src = URL.createObjectURL(file);
        el.style.maxHeight = '100px';
      } else if (file.type.startsWith('image')) {
        el = document.createElement('img');
        el.src = URL.createObjectURL(file);
        el.style.maxHeight = '100px';
      }
      if (el) previewsDiv.appendChild(el);
    }

    // On file select
    input.addEventListener('change', (e) => {
      progressDiv.innerHTML = '';
      previewsDiv.innerHTML = '';
      Array.from(input.files).forEach(file => {
        renderPreview(file);
        uploadFile(file);
      });
    });

    // On mount: resume incomplete uploads
    window.addEventListener('DOMContentLoaded', async () => {
      const db = await openDB();
      const tx = db.transaction(storeName, 'readonly');
      const req = tx.objectStore(storeName).getAll();
      req.onsuccess = () => {
        (req.result || []).forEach(async (rec) => {
          // Optionally, ask user to resume
          renderProgress(rec.fileId, rec.name, rec.bytesUploaded, rec.size);
          // Try to resume
          const fileList = Array.from(input.files);
          const file = fileList.find(f => getFileId(f) === rec.fileId);
          if (file) uploadFile(file);
        });
      };
    });
  }
};

export default ChunkedUploader;
