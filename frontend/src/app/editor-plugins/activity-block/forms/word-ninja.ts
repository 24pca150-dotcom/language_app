export function renderWordNinjaForm(
  parent: HTMLDivElement,
  data: any,
  renderExplanationInput: (parent: HTMLDivElement, data: any) => void
): void {
  // Ensure data structure
  if (!data.question) {
    data.question = 'Slice all Adjectives!';
  }
  if (!data.correctWords || !Array.isArray(data.correctWords)) {
    data.correctWords = ['Brave', 'Gentle', 'Bright', 'Honest', 'Swift', 'Happy', 'Clever'];
  }
  if (!data.wrongWords || !Array.isArray(data.wrongWords)) {
    data.wrongWords = ['Run', 'Eat', 'Quickly', 'Table', 'Sleep', 'Loudly', 'Jump'];
  }
  if (!data.speed) {
    data.speed = 'normal';
  }

  // 1. Info Banner
  const info = document.createElement('div');
  info.style.marginBottom = '1.25rem';
  info.innerHTML = `
    <div style="background: rgba(16, 185, 129, 0.1); border-left: 4px solid #10b981; padding: 0.85rem 1rem; border-radius: 0.5rem; color: #065f46; font-size: 0.9rem;">
      <strong>⚔️ Word Ninja (Fruit & Word Slicer):</strong> Words launch into the air with gravity physics. Learners slice across target words using their mouse or touch swipe while avoiding wrong distractors.
    </div>
  `;
  parent.appendChild(info);

  // 2. Mission Prompt Input
  const promptGroup = document.createElement('div');
  promptGroup.classList.add('activity-form-group');
  promptGroup.style.marginBottom = '1.25rem';
  promptGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #334155;">Slice Mission Prompt</label>
    <input type="text" class="ninja-prompt-input" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.5rem 0.75rem; font-size: 0.95rem;"
           placeholder="e.g. Slice all Adjectives! / Slice Synonyms of 'Happy'" value="${data.question || ''}">
  `;
  const promptInput = promptGroup.querySelector('.ninja-prompt-input') as HTMLInputElement;
  promptInput.addEventListener('input', (e: any) => {
    data.question = e.target.value;
  });
  parent.appendChild(promptGroup);

  // 3. Target Words (Correct)
  const correctGroup = document.createElement('div');
  correctGroup.classList.add('activity-form-group');
  correctGroup.style.marginBottom = '1.25rem';
  correctGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #059669;">
      <span style="display: inline-block; width: 8px; height: 8px; background: #059669; border-radius: 50%; margin-right: 4px;"></span>
      Correct Words to Slice (Comma-separated)
    </label>
    <textarea class="ninja-correct-input" rows="2" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.5rem 0.75rem; font-size: 0.9rem;"
              placeholder="e.g. Brave, Gentle, Bright, Honest, Swift, Happy">${data.correctWords.join(', ')}</textarea>
  `;
  const correctInput = correctGroup.querySelector('.ninja-correct-input') as HTMLTextAreaElement;
  correctInput.addEventListener('input', (e: any) => {
    data.correctWords = e.target.value.split(',').map((w: string) => w.trim()).filter((w: string) => w.length > 0);
  });
  parent.appendChild(correctGroup);

  // 4. Distractor Words (Wrong)
  const wrongGroup = document.createElement('div');
  wrongGroup.classList.add('activity-form-group');
  wrongGroup.style.marginBottom = '1.25rem';
  wrongGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #dc2626;">
      <span style="display: inline-block; width: 8px; height: 8px; background: #dc2626; border-radius: 50%; margin-right: 4px;"></span>
      Wrong Words / Distractors to Avoid (Comma-separated)
    </label>
    <textarea class="ninja-wrong-input" rows="2" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.5rem 0.75rem; font-size: 0.9rem;"
              placeholder="e.g. Run, Eat, Quickly, Table, Sleep, Loudly">${data.wrongWords.join(', ')}</textarea>
  `;
  const wrongInput = wrongGroup.querySelector('.ninja-wrong-input') as HTMLTextAreaElement;
  wrongInput.addEventListener('input', (e: any) => {
    data.wrongWords = e.target.value.split(',').map((w: string) => w.trim()).filter((w: string) => w.length > 0);
  });
  parent.appendChild(wrongGroup);

  // 5. Speed Setting
  const speedGroup = document.createElement('div');
  speedGroup.classList.add('activity-form-group');
  speedGroup.style.marginBottom = '1.25rem';
  speedGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #334155;">Launch Pace</label>
    <div style="display: flex; gap: 1rem;">
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="ninja-speed" value="normal" ${data.speed === 'normal' ? 'checked' : ''}> Normal (Relaxed)
      </label>
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="ninja-speed" value="fast" ${data.speed === 'fast' ? 'checked' : ''}> Fast (Challenging)
      </label>
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="ninja-speed" value="ninja" ${data.speed === 'ninja' ? 'checked' : ''}> Ninja Master (Fast & furious)
      </label>
    </div>
  `;
  const speedRadios = speedGroup.querySelectorAll('input[name="ninja-speed"]');
  speedRadios.forEach(radio => {
    radio.addEventListener('change', (e: any) => {
      data.speed = e.target.value;
    });
  });
  parent.appendChild(speedGroup);

  // 6. Explanation
  renderExplanationInput(parent, data);
}
