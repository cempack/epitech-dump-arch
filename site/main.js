// Copy buttons + directional slide-from-right scroll showcase.
// Without JS, every feature keeps its screenshot inline.

for (const box of document.querySelectorAll("[data-copy]")) {
  const label = box.querySelector(".copy-label");
  let timer;
  box.querySelector(".copy").addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(box.dataset.copy);
      label.textContent = "Copied";
    } catch {
      const range = document.createRange();
      range.selectNodeContents(box.querySelector("code"));
      getSelection().removeAllRanges();
      getSelection().addRange(range);
      label.textContent = "Ctrl+C";
    }
    clearTimeout(timer);
    timer = setTimeout(() => { label.textContent = "Copy"; }, 2000);
  });
}

const story = document.querySelector(".story");
if (story) {
  const frame = story.querySelector(".stage-frame");
  const count = story.querySelector(".stage-count");
  const dotsBox = story.querySelector(".stage-dots");
  const prevBtn = story.querySelector('[data-nav="prev"]');
  const nextBtn = story.querySelector('[data-nav="next"]');
  const steps = [...story.querySelectorAll(".step")];
  const shots = [];
  const dots = [];
  let current = 0;

  const jumpTo = (idx) => {
    const clamped = Math.max(0, Math.min(steps.length - 1, idx));
    steps[clamped].scrollIntoView({ behavior: "smooth", block: "center" });
  };

  steps.forEach((step, idx) => {
    const shot = step.querySelector(".shot").cloneNode(true);
    for (const img of shot.querySelectorAll("img")) img.loading = "eager";
    frame.appendChild(shot);
    shots.push(shot);

    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "stage-dot";
    btn.setAttribute("aria-label", `Jump to feature ${idx + 1}`);
    btn.innerHTML = "<span></span>";
    btn.addEventListener("click", () => jumpTo(idx));
    dotsBox.appendChild(btn);
    dots.push(btn);
  });

  story.classList.add("staged");

  const activate = (n) => {
    current = n;
    const tint = steps[n].dataset.tint || "green";
    story.dataset.tint = tint;

    steps.forEach((s, i) => s.classList.toggle("active", i === n));
    shots.forEach((shot, i) => {
      const state = i === n ? "active" : i < n ? "prev" : "next";
      shot.dataset.state = state;
    });
    dots.forEach((d, i) => {
      d.classList.toggle("on", i === n);
      d.setAttribute("aria-current", i === n ? "true" : "false");
    });

    const cur = String(n + 1).padStart(2, "0");
    const tot = String(steps.length).padStart(2, "0");
    count.textContent = `${cur} / ${tot}`;
    if (prevBtn) prevBtn.disabled = n === 0;
    if (nextBtn) nextBtn.disabled = n === steps.length - 1;
  };

  activate(0);

  if (prevBtn) prevBtn.addEventListener("click", () => jumpTo(current - 1));
  if (nextBtn) nextBtn.addEventListener("click", () => jumpTo(current + 1));

  // Pick the step closest to the viewport center on scroll (smoother than
  // single-pixel intersection triggers, especially on fast scrolls).
  let ticking = false;
  const syncFromScroll = () => {
    ticking = false;
    const mid = window.innerHeight * 0.5;
    let best = current;
    let bestDist = Infinity;
    for (let i = 0; i < steps.length; i++) {
      const rect = steps[i].getBoundingClientRect();
      const center = rect.top + rect.height * 0.5;
      const dist = Math.abs(center - mid);
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    if (best !== current) activate(best);
  };

  window.addEventListener("scroll", () => {
    if (!ticking) {
      ticking = true;
      requestAnimationFrame(syncFromScroll);
    }
  }, { passive: true });
}
