import { environment } from '../../../../environments/environment';

const isImageUrl = (url: string) => {
  if (!url) return false;
  const cleanUrl = url.split('?')[0].split('#')[0];
  return /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(cleanUrl);
};

const uploadFile = async (file: File): Promise<string> => {
  const token = localStorage.getItem('auth_token');
  const tenantCode = localStorage.getItem('tenant_code');
  const headers: any = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;
  if (tenantCode) headers['X-Tenant-Code'] = tenantCode;

  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch(`${environment.apiUrl}/contents/upload`, {
    method: 'POST',
    headers,
    body: formData
  });

  if (!response.ok) {
    throw new Error('Upload failed with status ' + response.status);
  }

  const result = await response.json();
  if (result && result.url) {
    return result.url;
  }
  throw new Error('Invalid response structure');
};

export function renderMatchForm(
  parent: HTMLDivElement,
  data: any,
  renderExplanationInput: (parent: HTMLDivElement, data: any) => void
): void {
  // 1. Config Section (Theme, Mode, Audio)
  const configGroup = document.createElement('div');
  configGroup.classList.add('activity-form-group');
  configGroup.style.display = 'grid';
  configGroup.style.gridTemplateColumns = 'repeat(auto-fit, minmax(180px, 1fr))';
  configGroup.style.gap = '1rem';
  configGroup.style.marginBottom = '1.5rem';
  configGroup.style.background = '#f1f5f9';
  configGroup.style.padding = '1.25rem';
  configGroup.style.borderRadius = '0.75rem';
  configGroup.style.border = '1px solid #e2e8f0';

  configGroup.innerHTML = `
    <div style="display: flex; flex-direction: column; justify-content: center;">
      <label class="activity-editor-label" style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; margin-bottom: 0;">
        <input type="checkbox" class="match-cloud-theme" ${data.theme === 'cloud' ? 'checked' : ''} style="width: 1.15rem; height: 1.15rem;">
        Cloud Layout
      </label>
    </div>
    <div style="display: flex; flex-direction: column; justify-content: center;">
      <label class="activity-editor-label" style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; margin-bottom: 0;">
        <input type="checkbox" class="match-drag-drop" ${data.allowDragDrop ? 'checked' : ''} style="width: 1.15rem; height: 1.15rem;">
        Drag & Drop
      </label>
    </div>
    <div style="display: flex; flex-direction: column; justify-content: center;">
      <label class="activity-editor-label" style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; margin-bottom: 0;">
        <input type="checkbox" class="match-click-match" ${data.allowClickMatch ? 'checked' : ''} style="width: 1.15rem; height: 1.15rem;">
        Click to Match
      </label>
    </div>
    <div style="display: flex; flex-direction: column; justify-content: center;">
      <label class="activity-editor-label" style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; margin-bottom: 0;">
        <input type="checkbox" class="match-enable-audio" ${data.enableAudio ? 'checked' : ''} style="width: 1.15rem; height: 1.15rem;">
        Audio
      </label>
    </div>
  `;

  // Bind configuration events
  const cloudThemeCheckbox = configGroup.querySelector('.match-cloud-theme') as HTMLInputElement;
  const dragDropCheckbox = configGroup.querySelector('.match-drag-drop') as HTMLInputElement;
  const clickMatchCheckbox = configGroup.querySelector('.match-click-match') as HTMLInputElement;
  const audioCheckbox = configGroup.querySelector('.match-enable-audio') as HTMLInputElement;

  cloudThemeCheckbox.addEventListener('change', (e: any) => { data.theme = e.target.checked ? 'cloud' : 'standard'; });
  dragDropCheckbox.addEventListener('change', (e: any) => { data.allowDragDrop = e.target.checked; });
  clickMatchCheckbox.addEventListener('change', (e: any) => { data.allowClickMatch = e.target.checked; });
  audioCheckbox.addEventListener('change', (e: any) => { data.enableAudio = e.target.checked; });

  parent.appendChild(configGroup);

  // 2. Pairs Table/Container
  const pairsGroup = document.createElement('div');
  pairsGroup.classList.add('activity-form-group');

  const label = document.createElement('label');
  label.classList.add('activity-editor-label');
  label.textContent = 'Match Pairs (Left Word -> Right Word/Image)';
  pairsGroup.appendChild(label);

  const rowsContainer = document.createElement('div');
  rowsContainer.classList.add('match-rows-container');

  const renderPairRows = () => {
    rowsContainer.innerHTML = '';
    data.pairs.forEach((pair: any, idx: number) => {
      const row = document.createElement('div');
      row.style.background = '#f8fafc';
      row.style.border = '1px solid #e2e8f0';
      row.style.borderRadius = '0.5rem';
      row.style.padding = '1rem';
      row.style.marginBottom = '0.75rem';

      row.innerHTML = `
        <div style="display: flex; flex-direction: column; gap: 0.75rem;">
          <div style="display: flex; gap: 0.75rem; align-items: center;">
            <div style="flex: 1; display: flex; flex-direction: column; gap: 0.25rem;">
              <span style="font-size: 0.8rem; font-weight: bold; color: #475569;">Left Cloud Element</span>
              <input type="text" class="activity-input-text pair-left" placeholder="Left Word" value="${pair.left || ''}" style="margin-bottom: 0;">
              
              <div style="display: flex; gap: 0.5rem; align-items: center; width: 100%;">
                <input type="text" class="activity-input-text pair-left-image" placeholder="Left Image URL (optional)" value="${pair.leftImage || ''}" style="margin-bottom: 0; font-size: 0.85rem; flex: 1;">
                <label class="activity-btn activity-btn-primary" style="margin-bottom: 0; padding: 0.25rem 0.5rem; font-size: 0.75rem; cursor: pointer; flex-shrink: 0; display: inline-flex; align-items: center; gap: 0.25rem;">
                  <i class="bi bi-upload"></i> Upload
                  <input type="file" accept="image/*" class="pair-left-image-file" style="display: none;">
                </label>
              </div>

              <div style="display: flex; gap: 0.5rem; align-items: center; width: 100%;">
                <input type="text" class="activity-input-text pair-left-audio" placeholder="Left Audio URL (optional)" value="${pair.leftAudio || ''}" style="margin-bottom: 0; font-size: 0.85rem; flex: 1;">
                <label class="activity-btn activity-btn-primary" style="margin-bottom: 0; padding: 0.25rem 0.5rem; font-size: 0.75rem; cursor: pointer; flex-shrink: 0; display: inline-flex; align-items: center; gap: 0.25rem;">
                  <i class="bi bi-upload"></i> Upload
                  <input type="file" accept="audio/*" class="pair-left-audio-file" style="display: none;">
                </label>
              </div>
            </div>
            
            <span style="color: #94a3b8; font-weight: bold; font-size: 1.5rem; margin-top: 1.25rem;">➔</span>
            
            <div style="flex: 1; display: flex; flex-direction: column; gap: 0.25rem;">
              <span style="font-size: 0.8rem; font-weight: bold; color: #475569;">Right Cloud Element</span>
              <input type="text" class="activity-input-text pair-right" placeholder="Right Word" value="${pair.right || ''}" style="margin-bottom: 0;">
              
              <div style="display: flex; gap: 0.5rem; align-items: center; width: 100%;">
                <input type="text" class="activity-input-text pair-right-image" placeholder="Right Image URL (optional)" value="${pair.rightImage || ''}" style="margin-bottom: 0; font-size: 0.85rem; flex: 1;">
                <label class="activity-btn activity-btn-primary" style="margin-bottom: 0; padding: 0.25rem 0.5rem; font-size: 0.75rem; cursor: pointer; flex-shrink: 0; display: inline-flex; align-items: center; gap: 0.25rem;">
                  <i class="bi bi-upload"></i> Upload
                  <input type="file" accept="image/*" class="pair-right-image-file" style="display: none;">
                </label>
              </div>

              <div style="display: flex; gap: 0.5rem; align-items: center; width: 100%;">
                <input type="text" class="activity-input-text pair-right-audio" placeholder="Right Audio URL (optional)" value="${pair.rightAudio || ''}" style="margin-bottom: 0; font-size: 0.85rem; flex: 1;">
                <label class="activity-btn activity-btn-primary" style="margin-bottom: 0; padding: 0.25rem 0.5rem; font-size: 0.75rem; cursor: pointer; flex-shrink: 0; display: inline-flex; align-items: center; gap: 0.25rem;">
                  <i class="bi bi-upload"></i> Upload
                  <input type="file" accept="audio/*" class="pair-right-audio-file" style="display: none;">
                </label>
              </div>
            </div>
            
            <button type="button" class="activity-btn activity-btn-danger pair-del" style="align-self: stretch; display: flex; align-items: center; justify-content: center; padding: 0.5rem 0.75rem; margin-bottom: 0; margin-top: 1.25rem;">&times;</button>
          </div>
          
          <div style="display: flex; gap: 0.75rem; align-items: center; background: #e2e8f0; padding: 0.5rem; border-radius: 0.375rem;">
            <label style="font-size: 0.8rem; font-weight: bold; color: #475569; margin-bottom: 0; flex-shrink: 0;">Compound Result Word (e.g., Sunflower):</label>
            <input type="text" class="activity-input-text pair-result" placeholder="Combined result word" value="${pair.result || ''}" style="flex: 1; margin-bottom: 0; font-size: 0.85rem;">
          </div>
        </div>
      `;

      // Bind pair inputs events
      const leftVal = row.querySelector('.pair-left') as HTMLInputElement;
      const leftImgVal = row.querySelector('.pair-left-image') as HTMLInputElement;
      const leftAudioVal = row.querySelector('.pair-left-audio') as HTMLInputElement;
      const rightVal = row.querySelector('.pair-right') as HTMLInputElement;
      const rightImgVal = row.querySelector('.pair-right-image') as HTMLInputElement;
      const rightAudioVal = row.querySelector('.pair-right-audio') as HTMLInputElement;
      const resultVal = row.querySelector('.pair-result') as HTMLInputElement;
      const delBtn = row.querySelector('.pair-del') as HTMLButtonElement;

      leftVal.addEventListener('input', (e: any) => { pair.left = e.target.value; });
      leftImgVal.addEventListener('input', (e: any) => { pair.leftImage = e.target.value; });
      leftAudioVal.addEventListener('input', (e: any) => { pair.leftAudio = e.target.value; });
      rightVal.addEventListener('input', (e: any) => { pair.right = e.target.value; });
      rightImgVal.addEventListener('input', (e: any) => { pair.rightImage = e.target.value; });
      rightAudioVal.addEventListener('input', (e: any) => { pair.rightAudio = e.target.value; });
      resultVal.addEventListener('input', (e: any) => { pair.result = e.target.value; });

      // Bind file input uploads
      const leftImgFile = row.querySelector('.pair-left-image-file') as HTMLInputElement;
      const leftAudioFile = row.querySelector('.pair-left-audio-file') as HTMLInputElement;
      const rightImgFile = row.querySelector('.pair-right-image-file') as HTMLInputElement;
      const rightAudioFile = row.querySelector('.pair-right-audio-file') as HTMLInputElement;

      const handleUpload = (fileInput: HTMLInputElement, textInput: HTMLInputElement, field: string) => {
        fileInput.addEventListener('change', async (e: any) => {
          const file = e.target.files?.[0];
          if (!file) return;

          textInput.value = 'Uploading...';
          textInput.disabled = true;

          try {
            const url = await uploadFile(file);
            pair[field] = url;
            textInput.value = url;
          } catch (err) {
            textInput.value = pair[field] || '';
            alert('Upload failed. Please try again.');
          } finally {
            textInput.disabled = false;
          }
        });
      };

      if (leftImgFile && leftImgVal) handleUpload(leftImgFile, leftImgVal, 'leftImage');
      if (leftAudioFile && leftAudioVal) handleUpload(leftAudioFile, leftAudioVal, 'leftAudio');
      if (rightImgFile && rightImgVal) handleUpload(rightImgFile, rightImgVal, 'rightImage');
      if (rightAudioFile && rightAudioVal) handleUpload(rightAudioFile, rightAudioVal, 'rightAudio');

      delBtn.addEventListener('click', () => {
        if (data.pairs.length > 1) {
          data.pairs.splice(idx, 1);
          renderPairRows();
        }
      });

      rowsContainer.appendChild(row);
    });
  };

  renderPairRows();
  pairsGroup.appendChild(rowsContainer);

  // Add pair button
  const addBtn = document.createElement('button');
  addBtn.type = 'button';
  addBtn.classList.add('activity-btn', 'activity-btn-primary', 'mt-1');
  addBtn.innerHTML = `+ Add Pair`;
  addBtn.addEventListener('click', () => {
    data.pairs.push({ left: '', right: '', rightImage: '', leftImage: '', leftAudio: '', rightAudio: '', result: '' });
    renderPairRows();
  });
  pairsGroup.appendChild(addBtn);

  parent.appendChild(pairsGroup);

  renderExplanationInput(parent, data);
}
