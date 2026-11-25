// Copy buttons, and the window that follows the story.
// Without JavaScript (and on phones) each chapter shows its own screenshot.

for (const box of document.querySelectorAll("[data-copy]")) {
  const button = box.querySelector(".copy");
  let timer;
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(box.dataset.copy);
      button.textContent = "Copied";
    } catch {
      const range = document.createRange();
      range.selectNodeContents(box.querySelector("code"));
      getSelection().removeAllRanges();
      getSelection().addRange(range);
      button.textContent = "Ctrl+C";
    }
    clearTimeout(timer);
    timer = setTimeout(() => { button.textContent = "Copy"; }, 2000);
  });
}

const show = document.querySelector(".show");
if (show) {
  const chapters = [...show.querySelectorAll(".chapter")];
  const framesBox = show.querySelector(".frames");
  const bar = show.querySelector(".dock-bar");
  const label = show.querySelector(".dock-label");
  const countLabel = show.querySelector(".dock-count");
  const titleLabel = show.querySelector(".dock-title");
  const [prevButton, nextButton] = show.querySelectorAll(".dock-nav button");
  const total = chapters.length - 1;
  const pad = (n) => String(n).padStart(2, "0");

  // One frame per chapter with a screenshot; the cover (index 0) has none.
  // A full Neovim screenshot fills the window's width; the others keep the
  // same scale, so the text is the same size in every frame.
  const fullWidth = Math.max(...chapters.map((c) => +(c.querySelector(".shot img")?.getAttribute("width") || 0)));
  const frames = chapters.map((chapter) => {
    const shot = chapter.querySelector(".shot");
    if (!shot) return null;
    const frame = shot.cloneNode(true);
    frame.classList.add("frame");
    const img = frame.querySelector("img");
    img.loading = "eager";
    img.style.width = `${(img.getAttribute("width") / fullWidth) * 100}%`;
    framesBox.appendChild(frame);
    return frame;
  });

  // Output taller than the window scrolls by once, at about 120px a second.
  const setPan = (frame) => {
    const img = frame.querySelector("img");
    const room = frame.clientHeight - img.offsetTop;
    const extra = Math.max(0, img.offsetHeight - room);
    frame.style.setProperty("--pan", `${-extra}px`);
    frame.style.setProperty("--pan-time", `${Math.max(1.5, extra / 120)}s`);
  };

  // The cover's fan: the first feature in front, two more behind it.
  const deck = { front: 1, mid: 4, back: 2 };

  // The progress bar: one segment per feature, a gap between acts.
  const segments = chapters.map((chapter, i) => {
    if (i === 0) return null;
    const button = document.createElement("button");
    button.type = "button";
    button.setAttribute("aria-label", chapter.dataset.title);
    button.innerHTML = "<span></span>";
    if (i > 1 && chapters[i - 1].dataset.act !== chapter.dataset.act) button.classList.add("act-start");
    button.addEventListener("click", () => go(i));
    bar.appendChild(button);
    return button;
  });

  let current = -1;
  const activate = (n) => {
    if (n === current) return;
    current = n;
    const chapter = chapters[n];
    show.dataset.act = chapter.dataset.act;
    chapters.forEach((c, i) => c.classList.toggle("active", i === n));
    frames.forEach((frame, i) => {
      if (!frame) return;
      delete frame.dataset.deck;
      if (n === 0) {
        const place = Object.keys(deck).find((key) => deck[key] === i);
        frame.dataset.state = place ? "deck" : "next";
        if (place) frame.dataset.deck = place;
      } else {
        frame.dataset.state = i === n ? "active" : i < n ? "prev" : "next";
        if (i === n) setPan(frame);
      }
    });
    segments.forEach((segment, i) => {
      if (!segment) return;
      segment.classList.toggle("on", i === n);
      segment.classList.toggle("done", i < n);
      segment.setAttribute("aria-current", i === n ? "step" : "false");
    });
    label.classList.toggle("idle", n === 0);
    countLabel.innerHTML = n === 0 ? "" : `<b>${pad(n)}</b> / ${pad(total)}`;
    titleLabel.textContent = n === 0 ? "Scroll to start" : chapter.dataset.title;
    prevButton.disabled = n === 0;
    nextButton.disabled = n === chapters.length - 1;
  };

  const go = (n) => {
    const target = chapters[Math.max(0, Math.min(chapters.length - 1, n))];
    target.scrollIntoView({ behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth", block: "center" });
  };
  prevButton.addEventListener("click", () => go(current - 1));
  nextButton.addEventListener("click", () => go(current + 1));

  // A chapter becomes the current one when it crosses the middle of the screen.
  const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) activate(chapters.indexOf(entry.target));
    }
  }, { rootMargin: "-48% 0px -48% 0px" });
  chapters.forEach((chapter) => observer.observe(chapter));

  show.classList.add("staged");
  activate(0);
}
