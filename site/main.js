// Copy buttons, and the scroll reveal. Without JavaScript the page is complete:
// the reveal only hides sections once this script has run.
document.documentElement.classList.add("js");

for (const box of document.querySelectorAll("[data-copy]")) {
  const button = box.querySelector(".copy");
  const label = button.querySelector(".copy-label");
  let timer;
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(box.dataset.copy);
      button.classList.add("done");
      label.textContent = "Copied";
    } catch {
      // No clipboard access (http, old browser): select the text instead.
      const range = document.createRange();
      range.selectNodeContents(box.querySelector("code"));
      getSelection().removeAllRanges();
      getSelection().addRange(range);
      label.textContent = "Press Ctrl+C";
    }
    clearTimeout(timer);
    timer = setTimeout(() => {
      button.classList.remove("done");
      label.textContent = "Copy";
    }, 2000);
  });
}

const sections = document.querySelectorAll(".reveal");
if ("IntersectionObserver" in window) {
  const io = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add("in");
        io.unobserve(entry.target);
      }
    }
  }, { threshold: 0.15 });
  sections.forEach((s) => io.observe(s));
} else {
  sections.forEach((s) => s.classList.add("in"));
}
