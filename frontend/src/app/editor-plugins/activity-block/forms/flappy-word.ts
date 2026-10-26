export function renderFlappyWordForm(
  parent: HTMLDivElement,
  data: any,
  renderExplanationInput: (parent: HTMLDivElement, data: any) => void
): void {
  if (!data.waves || !Array.isArray(data.waves) || data.waves.length === 0) {
    data.waves = [
      {
        question: "Fly to the Past Tense of 'Sing':",
        topOption: { text: 'Sang', isCorrect: true },
        bottomOption: { text: 'Singed', isCorrect: false }
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
    <div style="background: rgba(2, 132, 199, 0.1); border-left: 4px solid #0284c7; padding: 0.85rem 1rem; border-radius: 0.5rem; color: #0369a1; font-size: 0.9rem;">
      <strong>🕊️ Flappy Word (Sky Cloud Flight):</strong> Player controls a flying bird with taps or spacebar. Steer through the Top or Bottom cloud gate displaying the correct language answer.
    </div>
  `;
  parent.appendChild(info);

  // 2. Flight Pace
  const speedGroup = document.createElement('div');
  speedGroup.classList.add('activity-form-group');
  speedGroup.style.marginBottom = '1.25rem';
  speedGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #334155;">Flight Pace</label>
    <div style="display: flex; gap: 1rem;">
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="flappy-speed" value="gentle" ${data.speed === 'gentle' ? 'checked' : ''}> Gentle (Beginner)
      </label>
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="flappy-speed" value="normal" ${data.speed === 'normal' ? 'checked' : ''}> Normal (Balanced)
      </label>
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="flappy-speed" value="fast" ${data.speed === 'fast' ? 'checked' : ''}> Fast (Challenging)
      </label>
    </div>
  `;
  const speedRadios = speedGroup.querySelectorAll('input[name="flappy-speed"]');
  speedRadios.forEach(radio => {
    radio.addEventListener('change', (e: any) => {
      data.speed = e.target.value;
    });
  });
  parent.appendChild(speedGroup);

  // 3. Gate Waves List
  const wavesGroup = document.createElement('div');
  wavesGroup.classList.add('activity-form-group');
  wavesGroup.style.marginBottom = '1rem';

  const wavesLabel = document.createElement('label');
  wavesLabel.classList.add('activity-editor-label');
  wavesLabel.style.fontWeight = '600';
  wavesLabel.style.display = 'block';
  wavesLabel.style.marginBottom = '0.5rem';
  wavesLabel.textContent = 'Cloud Gate Challenges';
  wavesGroup.appendChild(wavesLabel);

  const wavesListContainer = document.createElement('div');
  wavesGroup.appendChild(wavesListContainer);

  const renderWaves = () => {
    wavesListContainer.innerHTML = '';

    data.waves.forEach((wave: any, waveIdx: number) => {
      if (!wave.topOption) wave.topOption = { text: '', isCorrect: true };
      if (!wave.bottomOption) wave.bottomOption = { text: '', isCorrect: false };

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
            ☁️ Cloud Gate #${waveIdx + 1}
          </span>
          <button type="button" class="del-wave-btn" style="background: none; border: none; color: #ef4444; font-size: 0.85rem; font-weight: 600; cursor: pointer; display: ${data.waves.length > 1 ? 'inline-block' : 'none'};">
            &times; Remove Gate
          </button>
        </div>

        <div style="margin-bottom: 0.75rem;">
          <label style="font-size: 0.8rem; font-weight: 600; color: #64748b; display: block; margin-bottom: 0.25rem;">Question / Clue</label>
          <input type="text" class="wave-question-input" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.45rem 0.65rem; font-size: 0.9rem;"
                 placeholder="e.g. Fly to the Past Tense of 'Sing':" value="${wave.question || ''}">
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
          <!-- Top Cloud -->
          <div style="background: #ffffff; border: 1px solid #cbd5e1; border-radius: 0.5rem; padding: 0.6rem;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.35rem;">
              <span style="font-size: 0.75rem; font-weight: 700; color: #0284c7;">TOP CLOUD GATE</span>
              <label style="font-size: 0.75rem; display: flex; align-items: center; gap: 0.25rem; cursor: pointer; color: #16a34a; font-weight: 600;">
                <input type="radio" name="flappy-correct-${waveIdx}" value="top" ${wave.topOption.isCorrect ? 'checked' : ''}> Correct
              </label>
            </div>
            <input type="text" class="top-cloud-input" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.35rem 0.5rem; font-size: 0.85rem;"
                   placeholder="Answer text" value="${wave.topOption.text || ''}">
          </div>

          <!-- Bottom Cloud -->
          <div style="background: #ffffff; border: 1px solid #cbd5e1; border-radius: 0.5rem; padding: 0.6rem;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.35rem;">
              <span style="font-size: 0.75rem; font-weight: 700; color: #0284c7;">BOTTOM CLOUD GATE</span>
              <label style="font-size: 0.75rem; display: flex; align-items: center; gap: 0.25rem; cursor: pointer; color: #16a34a; font-weight: 600;">
                <input type="radio" name="flappy-correct-${waveIdx}" value="bottom" ${wave.bottomOption.isCorrect ? 'checked' : ''}> Correct
              </label>
            </div>
            <input type="text" class="bottom-cloud-input" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.35rem 0.5rem; font-size: 0.85rem;"
                   placeholder="Answer text" value="${wave.bottomOption.text || ''}">
          </div>
        </div>
      `;

      // Event listeners
      const qInput = card.querySelector('.wave-question-input') as HTMLInputElement;
      qInput.addEventListener('input', (e: any) => { wave.question = e.target.value; });

      const topIn = card.querySelector('.top-cloud-input') as HTMLInputElement;
      topIn.addEventListener('input', (e: any) => { wave.topOption.text = e.target.value; });

      const btmIn = card.querySelector('.bottom-cloud-input') as HTMLInputElement;
      btmIn.addEventListener('input', (e: any) => { wave.bottomOption.text = e.target.value; });

      const radios = card.querySelectorAll(`input[name="flappy-correct-${waveIdx}"]`);
      radios.forEach((r: any) => {
        r.addEventListener('change', (e: any) => {
          wave.topOption.isCorrect = e.target.value === 'top';
          wave.bottomOption.isCorrect = e.target.value === 'bottom';
        });
      });

      const delBtn = card.querySelector('.del-wave-btn') as HTMLButtonElement;
      delBtn.addEventListener('click', () => {
        if (data.waves.length > 1) {
          data.waves.splice(waveIdx, 1);
          renderWaves();
        }
      });

      wavesListContainer.appendChild(card);
    });
  };

  renderWaves();

  // Add Gate Button
  const addGateBtn = document.createElement('button');
  addGateBtn.type = 'button';
  addGateBtn.style.padding = '0.5rem 1rem';
  addGateBtn.style.background = '#f1f5f9';
  addGateBtn.style.border = '1px dashed #94a3b8';
  addGateBtn.style.borderRadius = '0.5rem';
  addGateBtn.style.color = '#334155';
  addGateBtn.style.fontWeight = '600';
  addGateBtn.style.cursor = 'pointer';
  addGateBtn.style.width = '100%';
  addGateBtn.style.marginBottom = '1.25rem';
  addGateBtn.innerHTML = '+ Add Another Cloud Gate';
  addGateBtn.addEventListener('click', () => {
    data.waves.push({
      question: '',
      topOption: { text: '', isCorrect: true },
      bottomOption: { text: '', isCorrect: false }
    });
    renderWaves();
  });
  wavesGroup.appendChild(addGateBtn);

  parent.appendChild(wavesGroup);

  // 4. Explanation
  renderExplanationInput(parent, data);
}
