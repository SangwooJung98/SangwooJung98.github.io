$(document).ready(function () {
  // Native buttons provide Enter/Space support; hidden panels leave the focus order.
  document.querySelectorAll(".publications .links button[aria-controls]").forEach((button) => {
    button.addEventListener("click", () => {
      const open = button.getAttribute("aria-expanded") !== "true";
      button.parentElement.querySelectorAll("button[aria-controls]").forEach((control) => {
        const panel = document.getElementById(control.getAttribute("aria-controls"));
        const expanded = control === button && open;
        panel.hidden = !expanded;
        panel.classList.toggle("open", expanded);
        control.setAttribute("aria-expanded", String(expanded));
      });
    });
  });
  $("a, .publications .links button").removeClass("waves-effect waves-light");

  // bootstrap-toc
  if ($("#toc-sidebar").length) {
    // remove related publications years from the TOC
    $(".publications h2").each(function () {
      $(this).attr("data-toc-skip", "");
    });
    var navSelector = "#toc-sidebar";
    var $myNav = $(navSelector);
    Toc.init($myNav);
    const firstLink = $myNav.find("a")[0];
    const firstHeading = firstLink && document.getElementById(firstLink.hash.slice(1));
    // Use the same boundary as anchor scrolling, allowing for fractional pixels.
    const scrollMargin = firstHeading ? parseFloat(getComputedStyle(firstHeading).scrollMarginTop) || 0 : 0;
    $("body").scrollspy({
      target: navSelector,
      offset: Math.ceil(scrollMargin) + 1,
    });
  }
});
