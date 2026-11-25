// Copy buttons and the fixes tabs. Without JavaScript the page is complete:
// every fix is listed one after another.

for (const box of document.querySelectorAll("[data-copy]")) {
  const button = box.querySelector(".copy");
  let timer;
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(box.dataset.copy);
      button.textContent = "Copied";
    } catch {
      // No clipboard access: select the command so Ctrl+C works.
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

// Tabs, with the keyboard behavior of the WAI-ARIA tabs pattern:
// arrows move between tabs, Home and End jump to the ends.
for (const box of document.querySelectorAll("[data-tabs]")) {
  const tabs = [...box.querySelectorAll('[role="tab"]')];
  const panels = tabs.map((tab) => document.getElementById(tab.getAttribute("aria-controls")));

  const select = (index, focus) => {
    tabs.forEach((tab, i) => {
      const on = i === index;
      tab.setAttribute("aria-selected", String(on));
      tab.tabIndex = on ? 0 : -1;
      panels[i].hidden = !on;
    });
    if (focus) tabs[index].focus();
  };

  tabs.forEach((tab, i) => {
    tab.addEventListener("click", () => select(i, false));
    tab.addEventListener("keydown", (event) => {
      const last = tabs.length - 1;
      const vertical = getComputedStyle(tab.parentElement).flexDirection === "column";
      const next = vertical ? "ArrowDown" : "ArrowRight";
      const prev = vertical ? "ArrowUp" : "ArrowLeft";
      const to = { [next]: i === last ? 0 : i + 1, [prev]: i === 0 ? last : i - 1, Home: 0, End: last }[event.key];
      if (to !== undefined) {
        event.preventDefault();
        select(to, true);
      }
    });
  });

  box.classList.add("tabbed");
  select(0, false);
}
