module.exports = {
  content: ["_site/**/*.html", "_site/**/*.js"],
  css: ["_site/assets/css/*.css"],
  output: "_site/assets/css/",
  skippedContentGlobs: ["_site/assets/**/*.html"],
  // Classes added at runtime by the navigation, theme and bibliography controls.
  safelist: ["active", "collapse", "collapsing", "show", "open", "table-dark", "transition", "copy", "code-display-wrapper", "fa-clipboard-check"],
};
