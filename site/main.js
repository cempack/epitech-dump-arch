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
  const actLabel = show.querySelector(".dock-act");
  const titleLabel = show.querySelector(".dock-title");
  const [prevButton, nextButton] = show.querySelectorAll(".dock-nav button");
  const ACTS = { cover: "11 features", organize: "Organize", write: "Write", ship: "Ship", install: "Install" };

  // One frame per chapter with a screenshot; the cover (index 0) has none.
  const frames = chapters.map((chapter) => {
    const shot = chapter.querySelector(".shot");
    if (!shot) return null;
    const frame = shot.cloneNode(true);
    frame.className = "frame";
    frame.querySelector("img").loading = "eager";
    framesBox.appendChild(frame);
    return frame;
  });

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
      }
    });
    segments.forEach((segment, i) => {
      if (!segment) return;
      segment.classList.toggle("on", i === n);
      segment.classList.toggle("done", i < n);
      segment.setAttribute("aria-current", i === n ? "step" : "false");
    });
    actLabel.textContent = ACTS[chapter.dataset.act] || "";
    titleLabel.textContent = chapter.dataset.title;
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
