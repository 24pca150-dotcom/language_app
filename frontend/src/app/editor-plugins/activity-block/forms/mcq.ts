export function renderMCQForm(
  parent: HTMLDivElement,
  data: any,
  api: any,
  renderExplanationInput: (parent: HTMLDivElement, data: any) => void
): void {
  // 1. Question input
  const qGroup = document.createElement('div');
  qGroup.classList.add('activity-form-group');
  qGroup.innerHTML = `
    <label class="activity-editor-label">Question Text</label>
    <input type="text" class="activity-input-text mcq-question" value="${data.question || ''}" placeholder="E.g., What is the translation of 'Welcome'?">
  `;
  parent.appendChild(qGroup);

  const qInput = qGroup.querySelector('.mcq-question') as HTMLInputElement;
  qInput.addEventListener('input', (e: any) => { data.question = e.target.value; });

  // 1b. Audio URL input
  const audioGroup = document.createElement('div');
  audioGroup.classList.add('activity-form-group');
  audioGroup.innerHTML = `
    <label class="activity-editor-label">Pronunciation Audio URL (Optional)</label>
    <input type="text" class="activity-input-text mcq-audio" value="${data.audioUrl || ''}" placeholder="E.g., https://example.com/audio/pronounce.mp3">
  `;
  parent.appendChild(audioGroup);

  const audioInput = audioGroup.querySelector('.mcq-audio') as HTMLInputElement;
  audioInput.addEventListener('input', (e: any) => { data.audioUrl = e.target.value; });

  // 1c. Question Image URL input
  const imageGroup = document.createElement('div');
  imageGroup.classList.add('activity-form-group');
  imageGroup.innerHTML = `
    <label class="activity-editor-label">Question Image URL (Optional)</label>
    <input type="text" class="activity-input-text mcq-image" value="${data.imageUrl || ''}" placeholder="E.g., https://example.com/images/question.png">
  `;
  parent.appendChild(imageGroup);

  const imageInput = imageGroup.querySelector('.mcq-image') as HTMLInputElement;
  imageInput.addEventListener('input', (e: any) => { data.imageUrl = e.target.value; });

  // 2. Options list
  const optionsGroup = document.createElement('div');
  optionsGroup.classList.add('activity-form-group');

  const optionsLabel = document.createElement('label');
  optionsLabel.classList.add('activity-editor-label');
  optionsLabel.textContent = 'Answer Options (Select correct answer radio)';
  optionsGroup.appendChild(optionsLabel);

  const rowsContainer = document.createElement('div');
  rowsContainer.classList.add('mcq-rows-container');

  const renderOptionRows = () => {
    rowsContainer.innerHTML = '';
    data.options.forEach((opt: any, idx: number) => {
      const row = document.createElement('div');
      row.classList.add('activity-row');
      row.style.gap = '8px';

      const radio = document.createElement('input');
      radio.type = 'radio';
      radio.name = `mcq-correct-${api.blocks.getCurrentBlockIndex()}`;
      radio.classList.add('activity-radio');
      radio.checked = !!opt.isCorrect;
      radio.addEventListener('change', () => {
        data.options.forEach((o: any, i: number) => o.isCorrect = i === idx);
      });

      const input = document.createElement('input');
      input.type = 'text';
      input.classList.add('activity-input-text');
      input.style.flexGrow = '2';
      input.value = opt.text || '';
      input.placeholder = `Option Text ${idx + 1}`;
      input.addEventListener('input', (e: any) => {
        opt.text = e.target.value;
      });

      const optImage = document.createElement('input');
      optImage.type = 'text';
      optImage.classList.add('activity-input-text');
      optImage.style.flexGrow = '1';
      optImage.style.width = '20%';
      optImage.value = opt.imageUrl || '';
      optImage.placeholder = 'Image URL';
      optImage.addEventListener('input', (e: any) => {
        opt.imageUrl = e.target.value;
      });

      const optAudio = document.createElement('input');
      optAudio.type = 'text';
      optAudio.classList.add('activity-input-text');
      optAudio.style.flexGrow = '1';
      optAudio.style.width = '20%';
      optAudio.value = opt.audioUrl || '';
      optAudio.placeholder = 'Audio URL';
      optAudio.addEventListener('input', (e: any) => {
        opt.audioUrl = e.target.value;
      });

      const deleteBtn = document.createElement('button');
      deleteBtn.type = 'button';
      deleteBtn.classList.add('activity-btn', 'activity-btn-danger');
      deleteBtn.innerHTML = `&times; Delete`;
      deleteBtn.addEventListener('click', () => {
        if (data.options.length > 1) {
          data.options.splice(idx, 1);
          renderOptionRows();
        }
      });

      row.appendChild(radio);
      row.appendChild(input);
      row.appendChild(optImage);
      row.appendChild(optAudio);
      row.appendChild(deleteBtn);
      rowsContainer.appendChild(row);
    });
  };

  renderOptionRows();
  optionsGroup.appendChild(rowsContainer);

  // Add option button
  const addBtn = document.createElement('button');
  addBtn.type = 'button';
  addBtn.classList.add('activity-btn', 'activity-btn-primary', 'mt-2');
  addBtn.innerHTML = `+ Add Option`;
  addBtn.addEventListener('click', () => {
    data.options.push({ text: '', isCorrect: false, imageUrl: '', audioUrl: '' });
    renderOptionRows();
  });
  optionsGroup.appendChild(addBtn);

  parent.appendChild(optionsGroup);

  // 3. Explanation
  renderExplanationInput(parent, data);
}
