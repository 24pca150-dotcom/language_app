export function renderWritingForm(
  parent: HTMLDivElement,
  data: any,
  renderExplanationInput: (parent: HTMLDivElement, data: any) => void
): void {
  // Mode selection dropdown
  const modeGroup = document.createElement('div');
  modeGroup.classList.add('activity-form-group');
  modeGroup.innerHTML = `
    <label class="activity-editor-label">Writing Mode</label>
    <select class="activity-input-text writing-mode" style="width: 100%; padding: 0.5rem; border-radius: 0.375rem; border: 1px solid #cbd5e1;">
      <option value="standard" ${data.mode !== 'image_fill' ? 'selected' : ''}>Standard Essay / Story Writing</option>
      <option value="image_fill" ${data.mode === 'image_fill' ? 'selected' : ''}>Image Identification Fill-in-the-blanks</option>
    </select>
  `;
  parent.appendChild(modeGroup);

  const modeSelect = modeGroup.querySelector('.writing-mode') as HTMLSelectElement;

  // Question / instructions field
  const qGroup = document.createElement('div');
  qGroup.classList.add('activity-form-group');
  qGroup.innerHTML = `
    <label class="activity-editor-label">Instructions</label>
    <input type="text" class="activity-input-text writing-question" value="${data.question || 'Write a short story about the following prompt:'}" placeholder="Instructions for student">
  `;
  parent.appendChild(qGroup);

  const qInput = qGroup.querySelector('.writing-question') as HTMLInputElement;
  qInput.addEventListener('input', (e: any) => { data.question = e.target.value; });

  // Container for Standard Mode fields
  const standardContainer = document.createElement('div');
  standardContainer.style.display = data.mode !== 'image_fill' ? 'block' : 'none';

  const promptGroup = document.createElement('div');
  promptGroup.classList.add('activity-form-group');
  promptGroup.innerHTML = `
    <label class="activity-editor-label">Writing Prompt / Passage / Hints (Separate hints by newlines)</label>
    <textarea class="activity-textarea writing-text" rows="3" placeholder="Hints or details to display...">${data.text || ''}</textarea>
  `;
  standardContainer.appendChild(promptGroup);

  const promptTextarea = promptGroup.querySelector('.writing-text') as HTMLTextAreaElement;
  promptTextarea.addEventListener('input', (e: any) => { data.text = e.target.value; });

  const starterGroup = document.createElement('div');
  starterGroup.classList.add('activity-form-group');
  starterGroup.innerHTML = `
    <label class="activity-editor-label">Starter Sentence (Optional)</label>
    <input type="text" class="activity-input-text writing-starter" value="${data.starterText || ''}" placeholder="E.g. Once upon a time...">
  `;
  standardContainer.appendChild(starterGroup);

  const starterInput = starterGroup.querySelector('.writing-starter') as HTMLInputElement;
  starterInput.addEventListener('input', (e: any) => { data.starterText = e.target.value; });

  const limitGroup = document.createElement('div');
  limitGroup.classList.add('activity-form-group');
  limitGroup.style.display = 'flex';
  limitGroup.style.gap = '1rem';
  limitGroup.innerHTML = `
    <div style="flex: 1;">
      <label class="activity-editor-label">Min Word Limit</label>
      <input type="number" class="activity-input-text writing-min-words" value="${data.minWords || 1}">
    </div>
    <div style="flex: 1;">
      <label class="activity-editor-label">Max Word Limit</label>
      <input type="number" class="activity-input-text writing-max-words" value="${data.maxWords || 1000}">
    </div>
  `;
  standardContainer.appendChild(limitGroup);

  const minInput = limitGroup.querySelector('.writing-min-words') as HTMLInputElement;
  const maxInput = limitGroup.querySelector('.writing-max-words') as HTMLInputElement;
  minInput.addEventListener('input', (e: any) => { data.minWords = parseInt(e.target.value) || 1; });
  maxInput.addEventListener('input', (e: any) => { data.maxWords = parseInt(e.target.value) || 1000; });

  const modelGroup = document.createElement('div');
  modelGroup.classList.add('activity-form-group');
  modelGroup.innerHTML = `
    <label class="activity-editor-label">Model Reference Answer / Example Response</label>
    <textarea class="activity-textarea writing-model" rows="3" placeholder="Display this response after the student submits...">${data.modelAnswer || ''}</textarea>
  `;
  standardContainer.appendChild(modelGroup);

  const modelTextarea = modelGroup.querySelector('.writing-model') as HTMLTextAreaElement;
  modelTextarea.addEventListener('input', (e: any) => { data.modelAnswer = e.target.value; });

  parent.appendChild(standardContainer);

  // Container for Image Fill Mode fields
  const imageFillContainer = document.createElement('div');
  imageFillContainer.style.display = data.mode === 'image_fill' ? 'block' : 'none';

  const pairsGroup = document.createElement('div');
  pairsGroup.classList.add('activity-form-group');
  pairsGroup.innerHTML = `
    <label class="activity-editor-label">Image-Fill Pairs (Image & Answer Word)</label>
    <div class="writing-pairs-container"></div>
  `;
  imageFillContainer.appendChild(pairsGroup);

  const rowsContainer = pairsGroup.querySelector('.writing-pairs-container') as HTMLDivElement;

  const renderWritingPairs = () => {
    rowsContainer.innerHTML = '';
    if (!data.pairs) {
      data.pairs = [];
    }
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
            <!-- Left Side -->
            <div style="flex: 1; display: flex; flex-direction: column; gap: 0.25rem;">
              <span style="font-size: 0.8rem; font-weight: bold; color: #475569;">First Item</span>
              <input type="text" class="activity-input-text left-image" placeholder="Image URL" value="${pair.leftImage || ''}" style="margin-bottom: 0; font-size: 0.85rem;">
              <input type="text" class="activity-input-text left-answer" placeholder="Expected Text Answer" value="${pair.leftAnswer || ''}" style="margin-bottom: 0; font-size: 0.85rem;">
            </div>

            <!-- Divider -->
            <span style="color: #cbd5e1; font-weight: bold;">|</span>

            <!-- Right Side -->
            <div style="flex: 1; display: flex; flex-direction: column; gap: 0.25rem;">
              <span style="font-size: 0.8rem; font-weight: bold; color: #475569;">Second Item (Optional)</span>
              <input type="text" class="activity-input-text right-image" placeholder="Image URL" value="${pair.rightImage || ''}" style="margin-bottom: 0; font-size: 0.85rem;">
              <input type="text" class="activity-input-text right-answer" placeholder="Expected Text Answer" value="${pair.rightAnswer || ''}" style="margin-bottom: 0; font-size: 0.85rem;">
            </div>

            <!-- Delete Button -->
            <button type="button" class="activity-btn activity-btn-danger pair-del" style="align-self: stretch; display: flex; align-items: center; justify-content: center; padding: 0.5rem 0.75rem; margin-bottom: 0; margin-top: 1.25rem;">&times;</button>
          </div>
        </div>
      `;

      const leftImgInput = row.querySelector('.left-image') as HTMLInputElement;
      const leftAnsInput = row.querySelector('.left-answer') as HTMLInputElement;
      const rightImgInput = row.querySelector('.right-image') as HTMLInputElement;
      const rightAnsInput = row.querySelector('.right-answer') as HTMLInputElement;
      const delBtn = row.querySelector('.pair-del') as HTMLButtonElement;

      leftImgInput.addEventListener('input', (e: any) => { pair.leftImage = e.target.value; });
      leftAnsInput.addEventListener('input', (e: any) => { pair.leftAnswer = e.target.value; });
      rightImgInput.addEventListener('input', (e: any) => { pair.rightImage = e.target.value; });
      rightAnsInput.addEventListener('input', (e: any) => { pair.rightAnswer = e.target.value; });

      delBtn.addEventListener('click', () => {
        data.pairs.splice(idx, 1);
        renderWritingPairs();
      });

      rowsContainer.appendChild(row);
    });
  };

  const addPairBtn = document.createElement('button');
  addPairBtn.type = 'button';
  addPairBtn.classList.add('activity-btn', 'activity-btn-primary', 'mt-2');
  addPairBtn.innerHTML = `+ Add Item Pair`;
  addPairBtn.addEventListener('click', () => {
    if (!data.pairs) data.pairs = [];
    data.pairs.push({ leftImage: '', leftAnswer: '', rightImage: '', rightAnswer: '' });
    renderWritingPairs();
  });
  pairsGroup.appendChild(addPairBtn);

  renderWritingPairs();
  imageFillContainer.appendChild(pairsGroup);

  parent.appendChild(imageFillContainer);

  // Toggle sections based on mode selection
  modeSelect.addEventListener('change', (e: any) => {
    data.mode = e.target.value;
    if (data.mode === 'image_fill') {
      standardContainer.style.display = 'none';
      imageFillContainer.style.display = 'block';
      if (!data.pairs || data.pairs.length === 0) {
        data.pairs = [{ leftImage: '', leftAnswer: '', rightImage: '', rightAnswer: '' }];
        renderWritingPairs();
      }
    } else {
      standardContainer.style.display = 'block';
      imageFillContainer.style.display = 'none';
    }
  });

  renderExplanationInput(parent, data);
}
