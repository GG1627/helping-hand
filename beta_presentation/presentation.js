(() => {
  "use strict";
  const slides = [...document.querySelectorAll(".slide")];
  const stage = document.getElementById("stage");
  const deck = document.getElementById("deck");
  const progress = document.getElementById("slide-progress");
  const overview = document.getElementById("overview-dialog");
  const notes = document.getElementById("notes-dialog");
  const help = document.getElementById("help-dialog");
  const dialogs = [overview, notes, help];
  let current = 0;
  document.body.classList.add("enhanced");

  function fit() {
    const scale = Math.max(0.1, Math.min((stage.clientWidth - 24) / 1600, (stage.clientHeight - 24) / 900));
    deck.style.transform = `translate(-50%, -50%) scale(${scale})`;
  }
  function readHash() {
    const match = window.location.hash.match(/^#slide-(\d+)$/);
    return match ? Number(match[1]) - 1 : 0;
  }
  function updateNotes() {
    const content = document.getElementById("notes-content");
    content.replaceChildren();
    const title = document.createElement("h3");
    title.textContent = `${String(current + 1).padStart(2, "0")} · ${slides[current].dataset.title}`;
    content.append(title, slides[current].querySelector(".slide-notes").content.cloneNode(true));
  }
  function showSlide(index, updateHash = true) {
    current = Math.max(0, Math.min(slides.length - 1, index));
    slides.forEach((slide, i) => {
      const active = i === current;
      slide.classList.toggle("is-active", active);
      slide.setAttribute("aria-hidden", String(!active));
      slide.inert = !active;
    });
    progress.setAttribute("aria-valuemax", String(slides.length));
    progress.setAttribute("aria-valuenow", String(current + 1));
    progress.setAttribute("aria-valuetext", `Slide ${current + 1} of ${slides.length}`);
    progress.firstElementChild.style.width = `${((current + 1) / slides.length) * 100}%`;
    document.querySelectorAll("#overview-list button").forEach((button, i) => button.setAttribute("aria-current", String(i === current)));
    if (updateHash) history.replaceState(null, "", `#slide-${current + 1}`);
    document.getElementById("announcement").textContent = `Slide ${current + 1} of ${slides.length}: ${slides[current].dataset.title}`;
    updateNotes();
  }
  slides.forEach((slide, index) => {
    const button = document.createElement("button");
    const number = document.createElement("span");
    const title = document.createElement("strong");
    const duration = document.createElement("small");
    number.textContent = String(index + 1).padStart(2, "0");
    title.textContent = slide.dataset.title;
    duration.textContent = `${slide.dataset.seconds}s`;
    button.append(number, duration, title);
    button.addEventListener("click", () => { overview.close(); showSlide(index); });
    document.getElementById("overview-list").append(button);
  });
  function openDialog(dialog) {
    dialogs.filter(item => item !== dialog && item.open).forEach(item => item.close());
    if (dialog.open) dialog.close(); else dialog.showModal();
  }
  async function toggleFullScreen() {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else await document.documentElement.requestFullscreen();
    } catch {
      document.getElementById("announcement").textContent = "Full screen is unavailable. Use your browser's full screen control.";
    }
  }
  dialogs.forEach(dialog => {
    dialog.querySelector(".close-dialog").addEventListener("click", () => dialog.close());
    dialog.addEventListener("click", event => {
      if (event.target !== dialog) return;
      const bounds = dialog.getBoundingClientRect();
      if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) dialog.close();
    });
  });
  window.addEventListener("keydown", event => {
    if (event.ctrlKey || event.metaKey || event.altKey || event.target.closest("input, textarea, select, [contenteditable]")) return;
    if (dialogs.some(dialog => dialog.open)) return;
    const key = event.key.toLowerCase();
    if (event.target.closest("button") && (key === " " || key === "enter")) return;
    const actions = {
      arrowright: () => showSlide(current + 1), pagedown: () => showSlide(current + 1),
      " ": () => showSlide(current + (event.shiftKey ? -1 : 1)),
      arrowleft: () => showSlide(current - 1), pageup: () => showSlide(current - 1),
      home: () => showSlide(0), end: () => showSlide(slides.length - 1),
      o: () => openDialog(overview), n: () => openDialog(notes), "?": () => openDialog(help),
      f: toggleFullScreen, p: () => window.print()
    };
    if (actions[key]) { event.preventDefault(); actions[key](); }
  });
  window.addEventListener("hashchange", () => showSlide(readHash(), false));
  window.addEventListener("resize", fit);
  document.addEventListener("fullscreenchange", fit);
  new ResizeObserver(fit).observe(stage);
  window.addEventListener("beforeprint", () => slides.forEach(slide => { slide.inert = false; slide.removeAttribute("aria-hidden"); }));
  window.addEventListener("afterprint", () => showSlide(current, false));
  document.querySelectorAll("[data-asset]").forEach(slot => {
    if (!(window.HELPING_HAND_ASSETS || []).includes(slot.dataset.asset)) return;
    const img = new Image();
    img.alt = slot.dataset.alt;
    img.onload = () => {
      slot.querySelector(".asset-fallback, .hello-fallback").replaceWith(img);
      slot.classList.add("has-asset");
    };
    img.onerror = () => { /* Retain the labeled placeholder if a declared file is missing. */ };
    img.src = `assets/${slot.dataset.asset}`;
  });
  showSlide(readHash());
  fit();
})();
