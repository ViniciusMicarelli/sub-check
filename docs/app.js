// Troca de idioma (pt-BR / en) com memória local. Sem dependências.
(function () {
  function current() {
    var saved = null;
    try { saved = localStorage.getItem("subcheck-lang"); } catch (e) {}
    if (saved === "pt" || saved === "en") return saved;
    var nav = (navigator.language || "en").toLowerCase();
    return nav.indexOf("pt") === 0 ? "pt" : "en";
  }

  function apply(lang) {
    document.documentElement.lang = lang === "pt" ? "pt-BR" : "en";
    var nodes = document.querySelectorAll("[data-lang]");
    for (var i = 0; i < nodes.length; i++) {
      nodes[i].hidden = nodes[i].getAttribute("data-lang") !== lang;
    }
    var buttons = document.querySelectorAll("[data-lang-btn]");
    for (var j = 0; j < buttons.length; j++) {
      buttons[j].classList.toggle("active", buttons[j].getAttribute("data-lang-btn") === lang);
    }
  }

  window.setLang = function (lang) {
    try { localStorage.setItem("subcheck-lang", lang); } catch (e) {}
    apply(lang);
  };

  document.addEventListener("DOMContentLoaded", function () {
    apply(current());
  });
})();
