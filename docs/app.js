// Enshrouded SF Cheat Menu - Configurator Application Logic
(function() {
  'use strict';

  let baseData = JSON.parse(JSON.stringify(window.BASE_EXTENDED_MOD_JSON));
  let currentSettings = {};
  let originalDefaults = {};

  // Initialize currentSettings from baseData
  for (const [key, def] of Object.entries(baseData.settings)) {
    currentSettings[key] = def.value;
    originalDefaults[key] = def.value;
  }

  // DOM Elements
  const container = document.getElementById('categories-container');
  const jsonOutput = document.getElementById('json-output');
  const searchInput = document.getElementById('search-input');
  const copyBtn = document.getElementById('copy-btn');
  const downloadBtn = document.getElementById('download-btn');
  const importFile = document.getElementById('import-file');
  const resetBtn = document.getElementById('reset-btn');
  const presetContainer = document.getElementById('presets-list');
  const toastContainer = document.getElementById('toast-container');
  const modifiedCountEl = document.getElementById('modified-count');
  const expandAllBtn = document.getElementById('expand-all-btn');

  let activePresetKey = null;

  // Render Presets
  function renderPresets() {
    if (!presetContainer || !window.PRESETS) return;
    presetContainer.innerHTML = '';
    
    for (const [key, preset] of Object.entries(window.PRESETS)) {
      const chip = document.createElement('button');
      chip.className = `preset-chip ${activePresetKey === key ? 'active' : ''}`;
      chip.innerHTML = `${preset.name}`;
      chip.title = preset.desc;
      chip.addEventListener('click', () => applyPreset(key));
      presetContainer.appendChild(chip);
    }
  }

  // Apply a Preset
  function applyPreset(presetKey) {
    activePresetKey = presetKey;
    const preset = window.PRESETS[presetKey];
    if (!preset) return;

    // Reset to defaults first
    for (const [key, val] of Object.entries(originalDefaults)) {
      currentSettings[key] = val;
    }

    // Apply preset overrides
    for (const [key, val] of Object.entries(preset.values)) {
      if (currentSettings.hasOwnProperty(key)) {
        currentSettings[key] = val;
      }
    }

    updateUI();
    renderPresets();
    showToast(`Applied preset: ${preset.name}`);
  }

  // Determine Scope (Server or Personal)
  function getScope(key, def) {
    const label = (def.label || '').toLowerCase();
    const desc = (def.description || '').toLowerCase();
    if (label.includes('world') || label.includes('server') || desc.includes('world') || desc.includes('server')) {
      return { text: 'Server', class: 'server' };
    }
    return { text: 'Personal', class: 'personal' };
  }

  // Render All Categories and Settings
  function renderCategories() {
    if (!container || !baseData.groups) return;
    container.innerHTML = '';

    const query = (searchInput.value || '').trim().toLowerCase();

    baseData.groups.forEach((group, groupIdx) => {
      // Filter settings by search query
      const matchingKeys = group.settings.filter(key => {
        const def = baseData.settings[key];
        if (!def) return false;
        if (!query) return true;
        const text = `${def.label || ''} ${def.description || ''} ${key}`.toLowerCase();
        return text.includes(query);
      });

      if (matchingKeys.length === 0) return;

      const groupEl = document.createElement('div');
      groupEl.className = 'category-group';
      groupEl.id = `group-${groupIdx}`;

      // Count modified items in this group
      const modifiedInGroup = matchingKeys.filter(k => currentSettings[k] !== originalDefaults[k]).length;

      // Header
      const header = document.createElement('div');
      header.className = 'category-header';
      header.innerHTML = `
        <div class="category-title">
          <h2>${group.label}</h2>
          <span class="category-badge">${matchingKeys.length} settings</span>
          ${modifiedInGroup > 0 ? `<span class="category-badge" style="background: rgba(255, 122, 24, 0.25); color: #fff;">${modifiedInGroup} modified</span>` : ''}
        </div>
        <span class="category-arrow">▼</span>
      `;

      header.addEventListener('click', () => {
        groupEl.classList.toggle('collapsed');
      });

      // Description
      const descEl = document.createElement('div');
      descEl.className = 'category-desc';
      descEl.textContent = group.description;

      // Body
      const body = document.createElement('div');
      body.className = 'category-body';

      matchingKeys.forEach(key => {
        const def = baseData.settings[key];
        const val = currentSettings[key];
        const isModified = val !== originalDefaults[key];
        const scope = getScope(key, def);

        const card = document.createElement('div');
        card.className = `setting-card ${isModified ? 'modified' : ''}`;
        card.dataset.key = key;

        // Top info
        const top = document.createElement('div');
        top.className = 'setting-top';

        const meta = document.createElement('div');
        meta.className = 'setting-meta';
        meta.innerHTML = `
          <div class="setting-label">
            ${def.label || key}
            <span class="setting-scope ${scope.class}">${scope.text}</span>
          </div>
          <div class="setting-description">${def.description || ''}</div>
        `;
        top.appendChild(meta);

        // Control
        const controlContainer = document.createElement('div');

        if (def.control === 'checkbox') {
          const switchLabel = document.createElement('label');
          switchLabel.className = 'switch';
          const input = document.createElement('input');
          input.type = 'checkbox';
          input.checked = val === true;
          input.addEventListener('change', () => {
            currentSettings[key] = input.checked;
            updateUI();
          });
          const sliderSpan = document.createElement('span');
          sliderSpan.className = 'slider-round';
          switchLabel.appendChild(input);
          switchLabel.appendChild(sliderSpan);
          controlContainer.appendChild(switchLabel);
        } else if (def.control === 'slider') {
          const groupSlider = document.createElement('div');
          groupSlider.className = 'slider-control-group';

          const range = document.createElement('input');
          range.type = 'range';
          range.className = 'range-slider';
          range.min = def.min !== undefined ? def.min : 0;
          range.max = def.max !== undefined ? def.max : 100;
          range.step = def.step !== undefined ? def.step : 1;
          range.value = val;

          const num = document.createElement('input');
          num.type = 'number';
          num.className = 'number-input';
          num.min = range.min;
          num.max = range.max;
          num.step = range.step;
          num.value = val;

          range.addEventListener('input', () => {
            const numVal = parseFloat(range.value);
            num.value = numVal;
            currentSettings[key] = numVal;
            updateUI();
          });

          num.addEventListener('change', () => {
            let numVal = parseFloat(num.value);
            if (isNaN(numVal)) numVal = def.value;
            numVal = Math.max(parseFloat(range.min), Math.min(parseFloat(range.max), numVal));
            num.value = numVal;
            range.value = numVal;
            currentSettings[key] = numVal;
            updateUI();
          });

          groupSlider.appendChild(range);
          groupSlider.appendChild(num);
          controlContainer.appendChild(groupSlider);
        } else if (def.control === 'select') {
          const select = document.createElement('select');
          select.className = 'select-input';
          if (def.options) {
            for (const [optKey, optLabel] of Object.entries(def.options)) {
              const opt = document.createElement('option');
              opt.value = optKey;
              opt.textContent = optLabel;
              if (optKey === val) opt.selected = true;
              select.appendChild(opt);
            }
          }
          select.addEventListener('change', () => {
            currentSettings[key] = select.value;
            updateUI();
          });
          controlContainer.appendChild(select);
        }

        top.appendChild(controlContainer);
        card.appendChild(top);
        body.appendChild(card);
      });

      groupEl.appendChild(header);
      groupEl.appendChild(descEl);
      groupEl.appendChild(body);
      container.appendChild(groupEl);
    });
  }

  // Generate clean export JSON
  function generateOutputJSON() {
    const output = JSON.parse(JSON.stringify(baseData));
    for (const [key, val] of Object.entries(currentSettings)) {
      if (output.settings[key]) {
        output.settings[key].value = val;
      }
    }
    return JSON.stringify(output, null, 2);
  }

  // Highlight JSON string syntax
  function highlightJSON(jsonStr) {
    return jsonStr
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
        let cls = 'number';
        if (/^"/.test(match)) {
          if (/:$/.test(match)) {
            cls = 'key';
          } else {
            cls = 'string';
          }
        } else if (/true|false/.test(match)) {
          cls = 'boolean';
        } else if (/null/.test(match)) {
          cls = 'null';
        }
        return `<span style="${getColorForClass(cls)}">${match}</span>`;
      });
  }

  function getColorForClass(cls) {
    switch (cls) {
      case 'key': return 'color: #ff8c2b; font-weight: 600;';
      case 'string': return 'color: #a5d6a7;';
      case 'number': return 'color: #ffd54f;';
      case 'boolean': return 'color: #4fc3f7; font-weight: 600;';
      default: return 'color: #e0e0e0;';
    }
  }

  // Update UI and JSON Output
  function updateUI() {
    const jsonStr = generateOutputJSON();
    if (jsonOutput) {
      jsonOutput.innerHTML = highlightJSON(jsonStr);
    }

    // Update Modified Counter
    let count = 0;
    for (const [key, val] of Object.entries(currentSettings)) {
      if (val !== originalDefaults[key]) count++;
    }
    if (modifiedCountEl) {
      modifiedCountEl.textContent = count;
    }

    // Refresh card modified states without full redraw if search hasn't changed
    document.querySelectorAll('.setting-card').forEach(card => {
      const key = card.dataset.key;
      if (key && currentSettings.hasOwnProperty(key)) {
        if (currentSettings[key] !== originalDefaults[key]) {
          card.classList.add('modified');
        } else {
          card.classList.remove('modified');
        }
      }
    });
  }

  // Toast Notification
  function showToast(message) {
    if (!toastContainer) return;
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerHTML = `<span>✓</span> <span>${message}</span>`;
    toastContainer.appendChild(toast);
    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 2500);
  }

  // Copy to Clipboard
  if (copyBtn) {
    copyBtn.addEventListener('click', () => {
      const jsonStr = generateOutputJSON();
      navigator.clipboard.writeText(jsonStr).then(() => {
        showToast('Configuration copied to clipboard!');
      }).catch(() => {
        // Fallback
        const textarea = document.createElement('textarea');
        textarea.value = jsonStr;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        textarea.remove();
        showToast('Configuration copied to clipboard!');
      });
    });
  }

  // Download File
  if (downloadBtn) {
    downloadBtn.addEventListener('click', () => {
      const jsonStr = generateOutputJSON();
      const blob = new Blob([jsonStr], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'extended.mod.json';
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      showToast('Downloaded extended.mod.json!');
    });
  }

  // Import File
  if (importFile) {
    importFile.addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = (event) => {
        try {
          const parsed = JSON.parse(event.target.result);
          if (parsed && parsed.settings) {
            let loadedCount = 0;
            for (const [key, obj] of Object.entries(parsed.settings)) {
              if (currentSettings.hasOwnProperty(key) && obj && obj.value !== undefined) {
                currentSettings[key] = obj.value;
                loadedCount++;
              }
            }
            activePresetKey = null;
            renderCategories();
            renderPresets();
            updateUI();
            showToast(`Successfully imported ${loadedCount} settings from file!`);
          } else {
            alert('Invalid format: Could not find "settings" object in the JSON file.');
          }
        } catch (err) {
          alert('Failed to parse JSON file: ' + err.message);
        }
      };
      reader.readAsText(file);
      e.target.value = '';
    });
  }

  // Search Input
  if (searchInput) {
    searchInput.addEventListener('input', () => {
      renderCategories();
      updateUI();
    });
  }

  // Reset to Defaults
  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      applyPreset('vanilla');
    });
  }

  // Expand / Collapse All
  let allCollapsed = false;
  if (expandAllBtn) {
    expandAllBtn.addEventListener('click', () => {
      allCollapsed = !allCollapsed;
      document.querySelectorAll('.category-group').forEach(group => {
        if (allCollapsed) {
          group.classList.add('collapsed');
        } else {
          group.classList.remove('collapsed');
        }
      });
      expandAllBtn.innerHTML = allCollapsed ? '<span>⊞</span> Expand All' : '<span>⊟</span> Collapse All';
    });
  }

  // Initialize
  renderPresets();
  renderCategories();
  updateUI();
})();
