// Keep the reading indicator in sync with expandable content and the navbar.
(() => {
  const progress = document.getElementById("progress");
  if (!progress) return;

  const navbar = document.getElementById("navbar");
  let frame = null;
  let layoutChanged = true;

  function update() {
    frame = null;
    if (layoutChanged) {
      layoutChanged = false;
      const height = navbar && document.body.classList.contains("fixed-top-nav") ? navbar.getBoundingClientRect().height : 0;
      const top = `${height}px`;
      if (document.body.classList.contains("fixed-top-nav") && document.body.style.paddingTop !== top) {
        document.body.style.paddingTop = top;
      }
      if (progress.style.top !== top) progress.style.top = top;
    }

    const root = document.scrollingElement;
    const distance = Math.max(0, root.scrollHeight - document.documentElement.clientHeight);
    // A progress element requires a positive max, even on a page without scrolling.
    progress.max = Math.max(1, distance);
    progress.value = Math.min(distance, Math.max(0, root.scrollTop));
  }

  function schedule() {
    if (frame === null) frame = window.requestAnimationFrame(update);
  }

  function refreshLayout() {
    layoutChanged = true;
    schedule();
  }

  const observer = new ResizeObserver(refreshLayout);
  observer.observe(document.body);
  if (navbar) observer.observe(navbar);
  window.addEventListener("resize", refreshLayout);
  window.addEventListener("load", refreshLayout);
  window.addEventListener("scroll", schedule, { passive: true });
  update();
})();
