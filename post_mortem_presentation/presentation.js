(() => {
  'use strict';
  const slides = [...document.querySelectorAll('.slide')];
  const main = slides.filter(slide => !slide.hasAttribute('data-backup'));
  const backups = slides.filter(slide => slide.hasAttribute('data-backup'));
  const stage = document.getElementById('stage');
  const deck = document.getElementById('deck');
  const progress = document.getElementById('slide-progress');
  const announcement = document.getElementById('announcement');
  const overview = document.getElementById('overview-dialog');
  const notes = document.getElementById('notes-dialog');
  const help = document.getElementById('help-dialog');
  const dialogs = [overview, notes, help];
  let current = main[0];
  let lastMain = current;
  document.body.classList.add('enhanced');

  function fit() {
    const scale = Math.min((stage.clientWidth - 16) / 1600, (stage.clientHeight - 16) / 900);
    deck.style.transform = `translate(-50%, -50%) scale(${Math.max(0.01, scale)})`;
  }

  function showSlide(slide, updateHash = true) {
    current = slides.includes(slide) ? slide : main[0];
    if (main.includes(current)) lastMain = current;
    slides.forEach(item => {
      const active = item === current;
      item.classList.toggle('is-active', active);
      item.setAttribute('aria-hidden', String(!active));
      item.inert = !active;
    });
    const group = current.hasAttribute('data-backup') ? backups : main;
    const index = group.indexOf(current);
    const label = `${group === main ? 'Slide' : 'Backup'} ${index + 1} of ${group.length}`;
    progress.setAttribute('aria-valuemax', String(group.length));
    progress.setAttribute('aria-valuenow', String(index + 1));
    progress.setAttribute('aria-valuetext', label);
    progress.firstElementChild.style.width = `${((index + 1) / group.length) * 100}%`;
    document.querySelectorAll('[data-slide-target]').forEach(button => {
      button.setAttribute('aria-current', String(button.dataset.slideTarget === current.id));
    });
    if (updateHash) history.replaceState(null, '', `#${current.id}`);
    announcement.textContent = `${label}: ${current.dataset.title}`;
    const title = document.createElement('h3');
    title.textContent = `${label} · ${current.dataset.title}`;
    document.getElementById('notes-content').replaceChildren(title, current.querySelector('.slide-notes').content.cloneNode(true));
  }

  function readHash() {
    return slides.find(slide => `#${slide.id}` === location.hash) || main[0];
  }

  function move(offset) {
    const group = current.hasAttribute('data-backup') ? backups : main;
    showSlide(group[Math.max(0, Math.min(group.length - 1, group.indexOf(current) + offset))]);
  }

  slides.forEach(slide => {
    const group = slide.hasAttribute('data-backup') ? backups : main;
    const button = document.createElement('button');
    button.dataset.slideTarget = slide.id;
    const number = document.createElement('span');
    number.textContent = String(group.indexOf(slide) + 1).padStart(2, '0');
    const title = document.createElement('strong');
    title.textContent = slide.dataset.title;
    const duration = document.createElement('small');
    duration.textContent = group === main ? `${slide.dataset.seconds}s` : 'Backup';
    button.append(number, duration, title);
    button.addEventListener('click', () => { overview.close(); showSlide(slide); });
    document.getElementById(group === main ? 'overview-main' : 'overview-backup').append(button);
  });

  function openDialog(dialog) {
    dialogs.filter(item => item !== dialog && item.open).forEach(item => item.close());
    if (dialog.open) dialog.close(); else dialog.showModal();
  }

  async function toggleFullscreen() {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else await document.documentElement.requestFullscreen();
    } catch {
      announcement.textContent = 'Fullscreen is unavailable. Use the browser fullscreen control.';
    }
  }

  dialogs.forEach(dialog => {
    dialog.querySelector('.close-dialog').addEventListener('click', () => dialog.close());
    dialog.addEventListener('click', event => {
      if (event.target !== dialog) return;
      const box = dialog.getBoundingClientRect();
      if (event.clientX < box.left || event.clientX > box.right || event.clientY < box.top || event.clientY > box.bottom) dialog.close();
    });
  });

  document.getElementById('include-backups').addEventListener('change', event => {
    document.body.classList.toggle('print-backup-slides', event.target.checked);
  });
  window.addEventListener('keydown', event => {
    if (event.ctrlKey || event.metaKey || event.altKey || event.target.closest('input, textarea, select, [contenteditable]')) return;
    if (dialogs.some(dialog => dialog.open)) return;
    const key = event.key.toLowerCase();
    if (event.target.closest('button, a') && (key === ' ' || key === 'enter')) return;
    const actions = {
      arrowright: () => move(1), pagedown: () => move(1),
      arrowleft: () => move(-1), pageup: () => move(-1),
      ' ': () => move(event.shiftKey ? -1 : 1),
      home: () => showSlide(main[0]), end: () => showSlide(main.at(-1)),
      b: () => showSlide(current.hasAttribute('data-backup') ? lastMain : backups[0]),
      o: () => openDialog(overview), n: () => openDialog(notes), '?': () => openDialog(help),
      f: toggleFullscreen, p: () => { dialogs.forEach(dialog => dialog.close()); window.print(); }
    };
    if (actions[key]) { event.preventDefault(); actions[key](); }
  });
  window.addEventListener('hashchange', () => showSlide(readHash(), false));
  window.addEventListener('resize', fit);
  document.addEventListener('fullscreenchange', fit);
  new ResizeObserver(fit).observe(stage);
  window.addEventListener('beforeprint', () => slides.forEach(slide => {
    slide.inert = false;
    slide.removeAttribute('aria-hidden');
  }));
  window.addEventListener('afterprint', () => showSlide(current, false));
  showSlide(readHash());
  fit();
})();
