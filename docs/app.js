// Enshrouded SF Cheat Menu - Configurator Application Logic
(function() {
  'use strict';

  let currentModKey = 'sf-cheatmenu';
  let modConfig = window.MOD_CONFIGS ? window.MOD_CONFIGS[currentModKey] : null;
  let baseData = modConfig ? JSON.parse(JSON.stringify(modConfig.base)) : JSON.parse(JSON.stringify(window.BASE_EXTENDED_MOD_JSON));

  let currentSettings = {};
  let originalDefaults = {};

  // Initialize currentSettings from baseData
  function initSettings() {
    currentSettings = {};
    originalDefaults = {};
    for (const [key, def] of Object.entries(baseData.settings)) {
      currentSettings[key] = def.value;
      originalDefaults[key] = def.value;
    }
  }
  initSettings();

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
  let expandedCategories = new Set();

  // Switch Target Mod (sf-cheatmenu vs sf-cheatmenu-assets)
  function switchMod(modKey) {
    if (!window.MOD_CONFIGS || !window.MOD_CONFIGS[modKey]) return;
    currentModKey = modKey;
    modConfig = window.MOD_CONFIGS[modKey];
    baseData = JSON.parse(JSON.stringify(modConfig.base));
    initSettings();

    activePresetKey = null;
    expandedCategories.clear();

    // Update active tab buttons
    document.querySelectorAll('.mod-tab').forEach(tab => {
      tab.classList.toggle('active', tab.dataset.mod === modKey);
    });

    // Update preview title
    const previewTitle = document.querySelector('.preview-title span:nth-child(2)');
    if (previewTitle) {
      previewTitle.textContent = `${modKey}/extended.mod.json`;
    }

    renderPresets();
    renderCategories();
    updateExpandAllButtonText();
    updateUI();
    showToast(`Switched to: ${modConfig.name}`);
  }

  // Setup Mod Tab Listeners
  document.querySelectorAll('.mod-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      const target = tab.dataset.mod;
      if (target && target !== currentModKey) {
        switchMod(target);
      }
    });
  });

  // Render Presets
  function renderPresets() {
    if (!presetContainer) return;
    presetContainer.innerHTML = '';
    
    const presets = modConfig && modConfig.presets ? modConfig.presets : (window.PRESETS || {});

    for (const [key, preset] of Object.entries(presets)) {
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
    const presets = modConfig && modConfig.presets ? modConfig.presets : (window.PRESETS || {});
    const preset = presets[presetKey];
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

    const query = (searchInput ? searchInput.value : '').trim().toLowerCase();

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
      const isExpanded = query ? true : expandedCategories.has(groupIdx);
      groupEl.className = `category-group ${isExpanded ? '' : 'collapsed'}`;
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
        if (expandedCategories.has(groupIdx)) {
          expandedCategories.delete(groupIdx);
          groupEl.classList.add('collapsed');
        } else {
          expandedCategories.add(groupIdx);
          groupEl.classList.remove('collapsed');
        }
        updateExpandAllButtonText();
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

        const info = document.createElement('div');
        info.className = 'setting-info';
        info.innerHTML = `
          <div class="setting-title-row">
            <span class="setting-label">${def.label || key}</span>
            <span class="setting-scope ${scope.class}">${scope.text}</span>
            <span class="setting-key">${key}</span>
          </div>
          <div class="setting-desc">${def.description || ''}</div>
        `;
        top.appendChild(info);

        // Control input
        const controlContainer = document.createElement('div');
        controlContainer.className = 'setting-control';

        if (def.control === 'checkbox') {
          const switchLabel = document.createElement('label');
          switchLabel.className = 'switch';
          const input = document.createElement('input');
          input.type = 'checkbox';
          input.checked = !!val;
          input.addEventListener('change', (e) => {
            currentSettings[key] = e.target.checked;
            activePresetKey = null;
            renderPresets();
            updateUI();
          });

          const slider = document.createElement('span');
          slider.className = 'slider';

          switchLabel.appendChild(input);
          switchLabel.appendChild(slider);
          controlContainer.appendChild(switchLabel);

        } else if (def.control === 'slider') {
          const sliderWrap = document.createElement('div');
          sliderWrap.className = 'slider-wrap';

          const range = document.createElement('input');
          range.type = 'range';
          range.className = 'range-input';
          range.min = def.min;
          range.max = def.max;
          range.step = def.step || 1;
          range.value = val;

          const numBadge = document.createElement('span');
          numBadge.className = 'slider-value';
          numBadge.textContent = val;

          range.addEventListener('input', (e) => {
            const num = parseFloat(e.target.value);
            currentSettings[key] = num;
            numBadge.textContent = num;
            activePresetKey = null;
            renderPresets();
            updateUI();
          });

          sliderWrap.appendChild(range);
          sliderWrap.appendChild(numBadge);
          controlContainer.appendChild(sliderWrap);
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

    // Refresh card modified states without full redraw
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
        showToast(`Configuration for ${currentModKey} copied to clipboard!`);
      }).catch(() => {
        const textarea = document.createElement('textarea');
        textarea.value = jsonStr;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        textarea.remove();
        showToast(`Configuration for ${currentModKey} copied to clipboard!`);
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
      showToast(`Downloaded extended.mod.json for ${currentModKey}!`);
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
            showToast(`Imported ${loadedCount} settings into ${currentModKey}!`);
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

  function updateExpandAllButtonText() {
    if (!expandAllBtn) return;
    const totalGroups = baseData.groups ? baseData.groups.length : 0;
    const isAllExpanded = totalGroups > 0 && expandedCategories.size === totalGroups;
    expandAllBtn.innerHTML = isAllExpanded ? '<span>⊟</span> Collapse All' : '<span>⊞</span> Expand All';
  }

  // Expand / Collapse All
  if (expandAllBtn) {
    expandAllBtn.addEventListener('click', () => {
      const totalGroups = baseData.groups ? baseData.groups.length : 0;
      if (expandedCategories.size === totalGroups) {
        expandedCategories.clear();
      } else {
        for (let i = 0; i < totalGroups; i++) {
          expandedCategories.add(i);
        }
      }
      renderCategories();
      updateExpandAllButtonText();
    });
  }

  // Initialize
  renderPresets();
  renderCategories();
  updateExpandAllButtonText();
  updateUI();
})();
