export function renderCarRacerForm(
  parent: HTMLDivElement,
  data: any,
  renderExplanationInput: (parent: HTMLDivElement, data: any) => void
): void {
  // Ensure data structure
  if (!data.rounds || !Array.isArray(data.rounds) || data.rounds.length === 0) {
    data.rounds = [
      {
        question: 'Choose the Past Tense of "Drive":',
        options: [
          { text: 'Drove', isCorrect: true },
          { text: 'Drived', isCorrect: false },
          { text: 'Driven', isCorrect: false }
        ]
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
    <div style="background: rgba(234, 179, 8, 0.1); border-left: 4px solid #eab308; padding: 0.85rem 1rem; border-radius: 0.5rem; color: #854d0e; font-size: 0.9rem;">
      <strong>🏎️ 3-Lane Highway Racer:</strong> The player's car drives continuously down a 3-lane highway. In each wave, steer into the lane containing the correct answer while dodging the other two obstacle lanes.
    </div>
  `;
  parent.appendChild(info);

  // 2. Speed Setting
  const speedGroup = document.createElement('div');
  speedGroup.classList.add('activity-form-group');
  speedGroup.style.marginBottom = '1.25rem';
  speedGroup.innerHTML = `
    <label class="activity-editor-label" style="display: block; font-weight: 600; margin-bottom: 0.4rem; color: #334155;">Highway Speed</label>
    <div style="display: flex; gap: 1rem;">
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="racer-speed" value="normal" ${data.speed === 'normal' ? 'checked' : ''}> Normal (Beginner friendly)
      </label>
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="racer-speed" value="fast" ${data.speed === 'fast' ? 'checked' : ''}> Fast (Challenging)
      </label>
      <label style="display: flex; align-items: center; gap: 0.4rem; font-size: 0.9rem; cursor: pointer;">
        <input type="radio" name="racer-speed" value="turbo" ${data.speed === 'turbo' ? 'checked' : ''}> Turbo (Expert)
      </label>
    </div>
  `;
  const speedRadios = speedGroup.querySelectorAll('input[name="racer-speed"]');
  speedRadios.forEach(radio => {
    radio.addEventListener('change', (e: any) => {
      data.speed = e.target.value;
    });
  });
  parent.appendChild(speedGroup);

  // 3. Question Waves Container
  const wavesGroup = document.createElement('div');
  wavesGroup.classList.add('activity-form-group');
  wavesGroup.style.marginBottom = '1rem';

  const wavesLabel = document.createElement('label');
  wavesLabel.classList.add('activity-editor-label');
  wavesLabel.style.fontWeight = '600';
  wavesLabel.style.display = 'block';
  wavesLabel.style.marginBottom = '0.5rem';
  wavesLabel.textContent = 'Race Waves / Questions';
  wavesGroup.appendChild(wavesLabel);

  const wavesListContainer = document.createElement('div');
  wavesGroup.appendChild(wavesListContainer);

  const renderWaves = () => {
    wavesListContainer.innerHTML = '';

    data.rounds.forEach((round: any, roundIdx: number) => {
      // Ensure exactly 3 options
      if (!round.options || round.options.length < 3) {
        round.options = [
          { text: round.options?.[0]?.text || '', isCorrect: true },
          { text: round.options?.[1]?.text || '', isCorrect: false },
          { text: round.options?.[2]?.text || '', isCorrect: false }
        ];
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
            🏁 Wave #${roundIdx + 1}
          </span>
          <button type="button" class="del-wave-btn" style="background: none; border: none; color: #ef4444; font-size: 0.85rem; font-weight: 600; cursor: pointer; display: ${data.rounds.length > 1 ? 'inline-block' : 'none'};">
            &times; Remove Wave
          </button>
        </div>

        <div style="margin-bottom: 0.75rem;">
          <label style="font-size: 0.8rem; font-weight: 600; color: #64748b; display: block; margin-bottom: 0.25rem;">Question / Prompt</label>
          <input type="text" class="wave-question-input" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.45rem 0.65rem; font-size: 0.9rem;"
                 placeholder="e.g. Find the antonym of 'Bitter':" value="${round.question || ''}">
        </div>

        <label style="font-size: 0.8rem; font-weight: 600; color: #64748b; display: block; margin-bottom: 0.35rem;">
          3-Lane Choices (Select the radio of the correct lane)
        </label>
        <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 0.75rem;">
          <!-- Lane 1 (Left) -->
          <div style="background: #ffffff; border: 1px solid #cbd5e1; border-radius: 0.5rem; padding: 0.6rem;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.35rem;">
              <span style="font-size: 0.75rem; font-weight: 700; color: #475569;">LANE 1 (LEFT)</span>
              <label style="font-size: 0.75rem; display: flex; align-items: center; gap: 0.25rem; cursor: pointer; color: #16a34a; font-weight: 600;">
                <input type="radio" name="wave-correct-${roundIdx}" value="0" ${round.options[0].isCorrect ? 'checked' : ''}> Correct
              </label>
            </div>
            <input type="text" class="lane-input-0" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.35rem 0.5rem; font-size: 0.85rem;"
                   placeholder="Answer text" value="${round.options[0].text || ''}">
          </div>

          <!-- Lane 2 (Middle) -->
          <div style="background: #ffffff; border: 1px solid #cbd5e1; border-radius: 0.5rem; padding: 0.6rem;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.35rem;">
              <span style="font-size: 0.75rem; font-weight: 700; color: #475569;">LANE 2 (MIDDLE)</span>
              <label style="font-size: 0.75rem; display: flex; align-items: center; gap: 0.25rem; cursor: pointer; color: #16a34a; font-weight: 600;">
                <input type="radio" name="wave-correct-${roundIdx}" value="1" ${round.options[1].isCorrect ? 'checked' : ''}> Correct
              </label>
            </div>
            <input type="text" class="lane-input-1" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.35rem 0.5rem; font-size: 0.85rem;"
                   placeholder="Answer text" value="${round.options[1].text || ''}">
          </div>

          <!-- Lane 3 (Right) -->
          <div style="background: #ffffff; border: 1px solid #cbd5e1; border-radius: 0.5rem; padding: 0.6rem;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.35rem;">
              <span style="font-size: 0.75rem; font-weight: 700; color: #475569;">LANE 3 (RIGHT)</span>
              <label style="font-size: 0.75rem; display: flex; align-items: center; gap: 0.25rem; cursor: pointer; color: #16a34a; font-weight: 600;">
                <input type="radio" name="wave-correct-${roundIdx}" value="2" ${round.options[2].isCorrect ? 'checked' : ''}> Correct
              </label>
            </div>
            <input type="text" class="lane-input-2" style="width: 100%; border: 1px solid #cbd5e1; border-radius: 0.375rem; padding: 0.35rem 0.5rem; font-size: 0.85rem;"
                   placeholder="Answer text" value="${round.options[2].text || ''}">
          </div>
        </div>
      `;

      // Event Listeners for Round Inputs
      const qInput = card.querySelector('.wave-question-input') as HTMLInputElement;
      qInput.addEventListener('input', (e: any) => {
        round.question = e.target.value;
      });

      const lane0 = card.querySelector('.lane-input-0') as HTMLInputElement;
      lane0.addEventListener('input', (e: any) => { round.options[0].text = e.target.value; });

      const lane1 = card.querySelector('.lane-input-1') as HTMLInputElement;
      lane1.addEventListener('input', (e: any) => { round.options[1].text = e.target.value; });

      const lane2 = card.querySelector('.lane-input-2') as HTMLInputElement;
      lane2.addEventListener('input', (e: any) => { round.options[2].text = e.target.value; });

      const radios = card.querySelectorAll(`input[name="wave-correct-${roundIdx}"]`);
      radios.forEach((r: any) => {
        r.addEventListener('change', (e: any) => {
          const val = parseInt(e.target.value, 10);
          round.options[0].isCorrect = val === 0;
          round.options[1].isCorrect = val === 1;
          round.options[2].isCorrect = val === 2;
        });
      });

      const delBtn = card.querySelector('.del-wave-btn') as HTMLButtonElement;
      delBtn.addEventListener('click', () => {
        if (data.rounds.length > 1) {
          data.rounds.splice(roundIdx, 1);
          renderWaves();
        }
      });

      wavesListContainer.appendChild(card);
    });
  };

  renderWaves();

  // Add Wave Button
  const addWaveBtn = document.createElement('button');
  addWaveBtn.type = 'button';
  addWaveBtn.style.padding = '0.5rem 1rem';
  addWaveBtn.style.background = '#f1f5f9';
  addWaveBtn.style.border = '1px dashed #94a3b8';
  addWaveBtn.style.borderRadius = '0.5rem';
  addWaveBtn.style.color = '#334155';
  addWaveBtn.style.fontWeight = '600';
  addWaveBtn.style.cursor = 'pointer';
  addWaveBtn.style.width = '100%';
  addWaveBtn.style.marginBottom = '1.25rem';
  addWaveBtn.innerHTML = '+ Add Another Race Wave';
  addWaveBtn.addEventListener('click', () => {
    data.rounds.push({
      question: '',
      options: [
        { text: '', isCorrect: true },
        { text: '', isCorrect: false },
        { text: '', isCorrect: false }
      ]
    });
    renderWaves();
  });
  wavesGroup.appendChild(addWaveBtn);

  parent.appendChild(wavesGroup);

  // 4. Explanation Input
  renderExplanationInput(parent, data);
}
