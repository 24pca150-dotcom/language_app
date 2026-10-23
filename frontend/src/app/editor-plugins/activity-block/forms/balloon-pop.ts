export function renderBalloonPopForm(
  parent: HTMLDivElement,
  data: any,
  renderExplanationInput: (parent: HTMLDivElement, data: any) => void
): void {
  // Ensure data structure
  if (!data.question) {
    data.question = 'Pop all Nature Words!';
  }
  if (!data.correctWords || !Array.isArray(data.correctWords)) {
    data.correctWords = ['Sun', 'Moon', 'Sky', 'Star', 'Cloud', 'Rain', 'Breeze'];
  }
  if (!data.wrongWords || !Array.isArray(data.wrongWords)) {
    data.wrongWords = ['Car', 'Table', 'Phone', 'Book', 'Shoe', 'Chair'];
  }
  if (!data.speed) {
    data.speed = 'normal';
  }

  // 1. Info Banner
  const info = document.createElement('div');
  info.style.marginBottom = '1.25rem';
  info.innerHTML = `
    <div style="background: rgba(56, 189, 248, 0.12); border-left: 4px solid #0284c7; padding: 0.85rem 1rem; border-radius: 0.5rem; color: #0369a1; font-size: 0.9rem;">
      <strong>🎈 Balloon Word Pop:</strong> Colorful balloons float up into the sky. Learners tap or click target vocabulary balloons before they float away while ignoring distractors.
    </div>
  `;
  parent.appendChild(info);

  // 2. Mission Prompt Input
  const promptGroup = document.createElement('div');
  promptGroup.classList.add('activity-form-group');
  promptGroup.style.marginBottom = '1.25rem';
  promptGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #334155;">Pop Mission Prompt</label>
    <input type="text" class="balloon-prompt-input" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.5rem 0.75rem; font-size: 0.95rem;"
           placeholder="e.g. Pop all Nature Words! / Pop Sight Words" value="${data.question || ''}">
  `;
  const promptInput = promptGroup.querySelector('.balloon-prompt-input') as HTMLInputElement;
  promptInput.addEventListener('input', (e: any) => {
    data.question = e.target.value;
  });
  parent.appendChild(promptGroup);

  // 3. Target Words (Correct)
  const correctGroup = document.createElement('div');
  correctGroup.classList.add('activity-form-group');
  correctGroup.style.marginBottom = '1.25rem';
  correctGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #0284c7;">
      <span style="display: inline-block; width: 8px; height: 8px; background: #0284c7; border-radius: 50%; margin-right: 4px;"></span>
      Target Words to Pop (Comma-separated)
    </label>
    <textarea class="balloon-correct-input" rows="2" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.5rem 0.75rem; font-size: 0.9rem;"
              placeholder="e.g. Sun, Moon, Sky, Star, Cloud, Rain">${data.correctWords.join(', ')}</textarea>
  `;
  const correctInput = correctGroup.querySelector('.balloon-correct-input') as HTMLTextAreaElement;
  correctInput.addEventListener('input', (e: any) => {
    data.correctWords = e.target.value.split(',').map((w: string) => w.trim()).filter((w: string) => w.length > 0);
  });
  parent.appendChild(correctGroup);

  // 4. Distractor Words (Wrong)
  const wrongGroup = document.createElement('div');
  wrongGroup.classList.add('activity-form-group');
  wrongGroup.style.marginBottom = '1.25rem';
  wrongGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #ef4444;">
      <span style="display: inline-block; width: 8px; height: 8px; background: #ef4444; border-radius: 50%; margin-right: 4px;"></span>
      Wrong Distractors (Comma-separated)
    </label>
    <textarea class="balloon-wrong-input" rows="2" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.5rem 0.75rem; font-size: 0.9rem;"
              placeholder="e.g. Car, Table, Phone, Book, Shoe">${data.wrongWords.join(', ')}</textarea>
  `;
  const wrongInput = wrongGroup.querySelector('.balloon-wrong-input') as HTMLTextAreaElement;
  wrongInput.addEventListener('input', (e: any) => {
    data.wrongWords = e.target.value.split(',').map((w: string) => w.trim()).filter((w: string) => w.length > 0);
  });
  parent.appendChild(wrongGroup);

  // 5. Float Speed Setting
  const speedGroup = document.createElement('div');
  speedGroup.classList.add('activity-form-group');
  speedGroup.style.marginBottom = '1.25rem';
  speedGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #334155;">Float Speed</label>
    <select class="balloon-speed-select" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.5rem 0.75rem; font-size: 0.9rem;">
      <option value="gentle" ${data.speed === 'gentle' ? 'selected' : ''}>Gentle Breeze (Slow & Relaxed - Great for young learners)</option>
      <option value="normal" ${data.speed === 'normal' || !data.speed ? 'selected' : ''}>Standard Flow (Medium pace)</option>
      <option value="breezy" ${data.speed === 'breezy' ? 'selected' : ''}>Windy Sky (Fast pace challenge)</option>
    </select>
  `;
  const speedSelect = speedGroup.querySelector('.balloon-speed-select') as HTMLSelectElement;
  speedSelect.addEventListener('change', (e: any) => {
    data.speed = e.target.value;
  });
  parent.appendChild(speedGroup);

  // 6. Explanation
  renderExplanationInput(parent, data);
}
