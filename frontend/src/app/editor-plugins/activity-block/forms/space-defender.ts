export function renderSpaceDefenderForm(
  parent: HTMLDivElement,
  data: any,
  renderExplanationInput: (parent: HTMLDivElement, data: any) => void
): void {
  if (!data.challenges || !Array.isArray(data.challenges) || data.challenges.length === 0) {
    data.challenges = [
      {
        question: "Shoot the Antonym of 'Cowardly':",
        targetWord: "Brave",
        distractors: ["Timid", "Fearful"]
      }
    ];
  }
  if (!data.speed) {
    data.speed = 'normal';
  }

  // 1. Info Banner
  const info = document.createElement('div');
  info.style.marginBottom = '1.25rem';
  info.innerHTML = `
    <div style="background: rgba(14, 165, 233, 0.1); border-left: 4px solid #0ea5e9; padding: 0.85rem 1rem; border-radius: 0.5rem; color: #0369a1; font-size: 0.9rem;">
      <strong>🚀 Space Word Defender (Galaxy Shooter):</strong> Words descend as alien defense pods. Steer your fighter ship with Left/Right keys and fire laser cannons to blast the correct target word.
    </div>
  `;
  parent.appendChild(info);

  // 2. Pace Setting
  const speedGroup = document.createElement('div');
  speedGroup.classList.add('activity-form-group');
  speedGroup.style.marginBottom = '1.25rem';
  speedGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #334155;">Sector Speed</label>
    <div style="display: flex; gap: 1rem;">
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="space-speed" value="normal" ${data.speed === 'normal' ? 'checked' : ''}> Normal (Balanced)
      </label>
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="space-speed" value="hyper" ${data.speed === 'hyper' ? 'checked' : ''}> Hyper (Fast descent)
      </label>
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="space-speed" value="inferno" ${data.speed === 'inferno' ? 'checked' : ''}> Inferno (Extreme arcade)
      </label>
    </div>
  `;
  const speedRadios = speedGroup.querySelectorAll('input[name="space-speed"]');
  speedRadios.forEach(radio => {
    radio.addEventListener('change', (e: any) => {
      data.speed = e.target.value;
    });
  });
  parent.appendChild(speedGroup);

  // 3. Challenges List
  const challengesGroup = document.createElement('div');
  challengesGroup.classList.add('activity-form-group');
  challengesGroup.style.marginBottom = '1rem';

  const chLabel = document.createElement('label');
  chLabel.classList.add('activity-editor-label');
  chLabel.style.fontWeight = '600';
  chLabel.style.display = 'block';
  chLabel.style.marginBottom = '0.5rem';
  chLabel.textContent = 'Defense Sectors / Questions';
  challengesGroup.appendChild(chLabel);

  const listContainer = document.createElement('div');
  challengesGroup.appendChild(listContainer);

  const renderChallenges = () => {
    listContainer.innerHTML = '';

    data.challenges.forEach((ch: any, idx: number) => {
      if (!ch.distractors || !Array.isArray(ch.distractors)) {
        ch.distractors = ['', ''];
      }

      const card = document.createElement('div');
      card.style.background = '#f8fafc';
      card.style.border = '1px solid #e2e8f0';
      card.style.borderRadius = '0.75rem';
      card.style.padding = '1rem';
      card.style.marginBottom = '1rem';
      card.style.boxShadow = '0 1px 3px rgba(0,0,0,0.05)';

      card.innerHTML = `
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem;">
          <span style="font-weight: 700; color: #1e293b; font-size: 0.95rem;">
            🛰️ Sector #${idx + 1}
          </span>
          <button type="button" class="del-ch-btn" style="background: none; border: none; color: #ef4444; font-size: 0.85rem; font-weight: 600; cursor: pointer; display: ${data.challenges.length > 1 ? 'inline-block' : 'none'};">
            &times; Remove Sector
          </button>
        </div>

        <div style="margin-bottom: 0.75rem;">
          <label style="font-size: 0.8rem; font-weight: 600; color: #64748b; display: block; margin-bottom: 0.25rem;">Question Prompt</label>
          <input type="text" class="ch-prompt-input" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.45rem 0.65rem; font-size: 0.9rem;"
                 placeholder="e.g. Shoot the Antonym of 'Cowardly':" value="${ch.question || ''}">
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
          <!-- Target Word (Correct) -->
          <div style="background: #ffffff; border: 1px solid #10b981; border-radius: 0.5rem; padding: 0.6rem;">
            <span style="font-size: 0.75rem; font-weight: 700; color: #10b981; display: block; margin-bottom: 0.35rem;">🎯 TARGET WORD (SHOOT THIS)</span>
            <input type="text" class="target-word-input" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.35rem 0.5rem; font-size: 0.85rem;"
                   placeholder="e.g. Brave" value="${ch.targetWord || ''}">
          </div>

          <!-- Distractors (Wrong) -->
          <div style="background: #ffffff; border: 1px solid #ef4444; border-radius: 0.5rem; padding: 0.6rem;">
            <span style="font-size: 0.75rem; font-weight: 700; color: #ef4444; display: block; margin-bottom: 0.35rem;">🚫 DISTRACTORS (AVOID SHOOTING)</span>
            <input type="text" class="distractor-input" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.35rem 0.5rem; font-size: 0.85rem;"
                   placeholder="Comma-separated: e.g. Timid, Fearful" value="${ch.distractors.join(', ')}">
          </div>
        </div>
      `;

      // Event Listeners
      const pInput = card.querySelector('.ch-prompt-input') as HTMLInputElement;
      pInput.addEventListener('input', (e: any) => { ch.question = e.target.value; });

      const tInput = card.querySelector('.target-word-input') as HTMLInputElement;
      tInput.addEventListener('input', (e: any) => { ch.targetWord = e.target.value; });

      const dInput = card.querySelector('.distractor-input') as HTMLInputElement;
      dInput.addEventListener('input', (e: any) => {
        ch.distractors = e.target.value.split(',').map((w: string) => w.trim()).filter((w: string) => w.length > 0);
      });

      const delBtn = card.querySelector('.del-ch-btn') as HTMLButtonElement;
      delBtn.addEventListener('click', () => {
        if (data.challenges.length > 1) {
          data.challenges.splice(idx, 1);
          renderChallenges();
        }
      });

      listContainer.appendChild(card);
    });
  };

  renderChallenges();

  // Add Button
  const addBtn = document.createElement('button');
  addBtn.type = 'button';
  addBtn.style.padding = '0.5rem 1rem';
  addBtn.style.background = '#f1f5f9';
  addBtn.style.border = '1px dashed #94a3b8';
  addBtn.style.borderRadius = '0.5rem';
  addBtn.style.color = '#334155';
  addBtn.style.fontWeight = '600';
  addBtn.style.cursor = 'pointer';
  addBtn.style.width = '100%';
  addBtn.style.marginBottom = '1.25rem';
  addBtn.innerHTML = '+ Add Another Defense Sector';
  addBtn.addEventListener('click', () => {
    data.challenges.push({
      question: '',
      targetWord: '',
      distractors: ['', '']
    });
    renderChallenges();
  });
  challengesGroup.appendChild(addBtn);

  parent.appendChild(challengesGroup);

  // 4. Explanation
  renderExplanationInput(parent, data);
}
