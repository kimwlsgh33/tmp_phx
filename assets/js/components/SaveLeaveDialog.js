// Simple custom modal dialog for Save and Leave
// Usage: showSaveLeaveDialog({onLeave, onSaveAndLeave})

export function showSaveLeaveDialog({onLeave, onSaveAndLeave}) {
  const overlay = document.createElement('div');
  overlay.style.position = 'fixed';
  overlay.style.inset = '0';
  overlay.style.background = 'rgba(0,0,0,0.4)';
  overlay.style.zIndex = '9999';
  overlay.style.display = 'flex';
  overlay.style.alignItems = 'center';
  overlay.style.justifyContent = 'center';

  const modal = document.createElement('div');
  modal.style.background = '#fff';
  modal.style.borderRadius = '12px';
  modal.style.padding = '2rem 2.5rem';
  modal.style.boxShadow = '0 4px 32px rgba(0,0,0,0.2)';
  modal.style.maxWidth = '90vw';
  modal.style.width = '350px';
  modal.style.textAlign = 'center';

  const title = document.createElement('h2');
  title.textContent = 'Unsaved Uploads';
  title.style.marginBottom = '1rem';
  title.style.fontSize = '1.2rem';
  modal.appendChild(title);

  const message = document.createElement('p');
  message.textContent = 'You have selected files but not uploaded them. What would you like to do?';
  message.style.marginBottom = '1.5rem';
  modal.appendChild(message);

  const btnLeave = document.createElement('button');
  btnLeave.textContent = 'Just Leave';
  btnLeave.style.margin = '0 0.5rem';
  btnLeave.style.padding = '0.5rem 1rem';
  btnLeave.style.background = '#e53e3e';
  btnLeave.style.color = '#fff';
  btnLeave.style.border = 'none';
  btnLeave.style.borderRadius = '4px';
  btnLeave.style.cursor = 'pointer';
  btnLeave.onclick = () => {
    document.body.removeChild(overlay);
    if (onLeave) onLeave();
  };

  const btnSave = document.createElement('button');
  btnSave.textContent = 'Save and Leave';
  btnSave.style.margin = '0 0.5rem';
  btnSave.style.padding = '0.5rem 1rem';
  btnSave.style.background = '#3182ce';
  btnSave.style.color = '#fff';
  btnSave.style.border = 'none';
  btnSave.style.borderRadius = '4px';
  btnSave.style.cursor = 'pointer';
  btnSave.onclick = () => {
    document.body.removeChild(overlay);
    if (onSaveAndLeave) onSaveAndLeave();
  };

  modal.appendChild(btnLeave);
  modal.appendChild(btnSave);
  overlay.appendChild(modal);
  document.body.appendChild(overlay);
}