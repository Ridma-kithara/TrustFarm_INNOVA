/* TrustFarm AI — theme, language, reveals, counters and the PPTX preview */
(function () {
  "use strict";

  var SUPPORTED = ["en", "si", "ta", "ja"];
  var root = document.documentElement;
  var dict = window.TF_I18N || { en: {} };
  var $ = function (sel, ctx) { return (ctx || document).querySelector(sel); };
  var $$ = function (sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); };

  /* ── Language ─────────────────────────────────────────────── */
  function applyLanguage(lang, options) {
    options = options || {};
    if (SUPPORTED.indexOf(lang) < 0) lang = "en";
    root.lang = lang;
    root.dataset.lang = lang;

    $$("[data-i18n]").forEach(function (el) {
      var key = el.getAttribute("data-i18n");
      var value = dict[lang] && dict[lang][key];
      if (typeof value === "string") el.textContent = value;
    });
    $$("[data-i18n-aria]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-aria");
      var value = dict[lang] && dict[lang][key];
      if (typeof value === "string") el.setAttribute("aria-label", value);
    });

    var select = $("#langSelect");
    if (select) select.value = lang;
    if (options.persist !== false) {
      try { localStorage.setItem("tf-lang", lang); } catch (e) {}
    }
    var presPrev = $("#presPrev");
    var presNext = $("#presNext");
    if (presPrev) presPrev.setAttribute("aria-label", (dict[lang] && dict[lang]["deck.prev"]) || "Previous slide");
    if (presNext) presNext.setAttribute("aria-label", (dict[lang] && dict[lang]["deck.next"]) || "Next slide");
    document.dispatchEvent(new CustomEvent("tf-language", { detail: { lang: lang } }));
  }

  /* ── Theme ────────────────────────────────────────────────── */
  function applyTheme(theme, options) {
    options = options || {};
    if (theme !== "light" && theme !== "dark") theme = "dark";
    root.dataset.theme = theme;
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute("content", theme === "light" ? "#f4faf6" : "#060d09");
    if (options.persist !== false) {
      try { localStorage.setItem("tf-theme", theme); } catch (e) {}
    }
    document.dispatchEvent(new CustomEvent("tf-theme", { detail: { theme: theme } }));
  }

  var themeToggle = $("#themeToggle");
  if (themeToggle) {
    themeToggle.addEventListener("click", function () {
      applyTheme(root.dataset.theme === "light" ? "dark" : "light");
    });
  }

  var langSelect = $("#langSelect");
  if (langSelect) {
    langSelect.addEventListener("change", function () { applyLanguage(langSelect.value); });
  }

  /* ── Menu ─────────────────────────────────────────────────── */
  var menuBtn = $("#menuBtn");
  var mobileMenu = $("#mobileMenu");
  function closeMenu() {
    if (!mobileMenu || !menuBtn) return;
    mobileMenu.classList.remove("open");
    menuBtn.setAttribute("aria-expanded", "false");
  }
  if (menuBtn && mobileMenu) {
    menuBtn.addEventListener("click", function () {
      var open = mobileMenu.classList.toggle("open");
      menuBtn.setAttribute("aria-expanded", open ? "true" : "false");
    });
    $$("a", mobileMenu).forEach(function (a) { a.addEventListener("click", closeMenu); });
    document.addEventListener("keydown", function (e) { if (e.key === "Escape") closeMenu(); });
    document.addEventListener("click", function (e) {
      if (!mobileMenu.contains(e.target) && !menuBtn.contains(e.target)) closeMenu();
    });
  }

  /* ── Header scroll state ──────────────────────────────────── */
  var header = $("#siteHeader");
  var onScroll = function () {
    if (!header) return;
    header.classList.toggle("scrolled", window.scrollY > 18);
  };
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* ── Reveal on scroll ─────────────────────────────────────── */
  var revealEls = $$(".reveal");
  if ("IntersectionObserver" in window) {
    var revealObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          revealObserver.unobserve(entry.target);
        }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.06 });
    revealEls.forEach(function (el) { revealObserver.observe(el); });
  } else {
    revealEls.forEach(function (el) { el.classList.add("in"); });
  }

  /* ── Gauge, counters and bars ─────────────────────────────── */
  var gauge = $("#gaugeValue");
  var gaugeNumber = $("#gaugeNumber");
  var gaugeCard = gauge && gauge.closest(".gauge-card");
  var gaugeDone = false;
  function animateGauge() {
    if (gaugeDone) return;
    gaugeDone = true;
    var score = 96;
    var c = 2 * Math.PI * 48;
    window.setTimeout(function () {
      gauge.style.strokeDashoffset = String(c * (1 - score / 100));
      if (gaugeNumber) {
        var start = performance.now();
        var dur = 1400;
        var tick = function (now) {
          var p = Math.min(1, (now - start) / dur);
          var eased = 1 - Math.pow(1 - p, 3);
          gaugeNumber.textContent = String(Math.round(score * eased));
          if (p < 1) requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
      }
    }, 160);
  }
  if (gaugeCard && "IntersectionObserver" in window) {
    var gaugeObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) { animateGauge(); gaugeObserver.disconnect(); }
      });
    }, { threshold: 0.35 });
    gaugeObserver.observe(gaugeCard);
  } else {
    animateGauge();
  }

  var bars = $$(".metric .bar i");
  if (bars.length && "IntersectionObserver" in window) {
    var barObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        bars.forEach(function (bar) {
          bar.style.width = (parseFloat(bar.getAttribute("data-width")) || 0) + "%";
        });
        barObserver.disconnect();
      });
    }, { threshold: 0.3 });
    barObserver.observe(bars[0].closest(".metrics"));
  } else {
    bars.forEach(function (bar) { bar.style.width = (parseFloat(bar.getAttribute("data-width")) || 0) + "%"; });
  }

  /* ── Presentation deck ────────────────────────────────────── */
  var SLIDES = [
    "Title & vision",
    "Team",
    "Problem",
    "SDG alignment",
    "Solution",
    "3D system view",
    "Digital twin · mobile",
    "Architecture",
    "Trust engine",
    "Decision flow",
    "AI forecasting",
    "Hardware",
    "Energy",
    "Applications",
    "Data foundation",
    "Dataset analysis · AquaIntel",
    "Dataset analysis · AgriField",
    "Dataset analysis · Energy + IoT",
    "Modelling",
    "Results",
    "Security & reliability",
    "Validation",
    "INNOVA live demo",
    "Impact & next gates",
    "Thank you"
  ];
  var BASE = "docs/project_visuals/presentation/slide-";
  var slideEl = $("#presSlide");
  var titleEl = $("#presTitle");
  var countEl = $("#presCount");
  var thumbsEl = $("#presThumbs");
  var stageEl = $("#presStage");
  var current = 0;

  function slideSrc(index) {
    return BASE + String(index + 1).padStart(2, "0") + ".jpg";
  }

  function showSlide(index, options) {
    options = options || {};
    if (!slideEl || !SLIDES.length) return;
    current = (index + SLIDES.length) % SLIDES.length;
    slideEl.src = slideSrc(current);
    slideEl.alt = "TrustFarm presentation slide " + (current + 1) + ": " + SLIDES[current];
    if (titleEl) titleEl.textContent = String(current + 1).padStart(2, "0") + " · " + SLIDES[current];
    if (countEl) countEl.textContent = (current + 1) + " / " + SLIDES.length;
    var thumbs = $$(".pres-thumb", thumbsEl);
    thumbs.forEach(function (thumb, i) {
      thumb.classList.toggle("active", i === current);
      if (i === current) {
        var left = thumb.offsetLeft - (thumbsEl.clientWidth - thumb.clientWidth) / 2;
        if (thumbsEl.scrollTo) {
          thumbsEl.scrollTo({ left: Math.max(0, left), behavior: options.instant ? "auto" : "smooth" });
        } else {
          thumbsEl.scrollLeft = Math.max(0, left);
        }
      }
    });
    // Preload neighbours for snappy navigation
    [current - 1, current + 1].forEach(function (i) {
      if (i >= 0 && i < SLIDES.length) { var img = new Image(); img.src = slideSrc(i); }
    });
  }

  if (thumbsEl && SLIDES.length) {
    SLIDES.forEach(function (title, i) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "pres-thumb" + (i === 0 ? " active" : "");
      btn.setAttribute("aria-label", "Slide " + (i + 1) + ": " + title);
      var img = document.createElement("img");
      img.src = slideSrc(i);
      img.alt = "";
      img.loading = "lazy";
      img.width = 320;
      img.height = 180;
      btn.appendChild(img);
      btn.addEventListener("click", function () { showSlide(i); });
      thumbsEl.appendChild(btn);
    });
  }

  function stepSlide(delta) { showSlide(current + delta); }
  var prevBtn = $("#presPrev");
  var nextBtn = $("#presNext");
  if (prevBtn) prevBtn.addEventListener("click", function () { stepSlide(-1); });
  if (nextBtn) nextBtn.addEventListener("click", function () { stepSlide(1); });

  if (stageEl) {
    stageEl.addEventListener("keydown", function (e) {
      if (e.key === "ArrowLeft") { e.preventDefault(); stepSlide(-1); }
      if (e.key === "ArrowRight") { e.preventDefault(); stepSlide(1); }
      if (e.key === "Home") { e.preventDefault(); showSlide(0); }
      if (e.key === "End") { e.preventDefault(); showSlide(SLIDES.length - 1); }
    });
    var touchX = null;
    stageEl.addEventListener("touchstart", function (e) {
      if (e.touches.length === 1) touchX = e.touches[0].clientX;
    }, { passive: true });
    stageEl.addEventListener("touchend", function (e) {
      if (touchX === null) return;
      var dx = (e.changedTouches[0] || {}).clientX - touchX;
      if (Math.abs(dx) > 46) stepSlide(dx < 0 ? 1 : -1);
      touchX = null;
    }, { passive: true });
    stageEl.addEventListener("dblclick", function () {
      if (stageEl.requestFullscreen) stageEl.requestFullscreen();
    });
  }

  var deckFull = $("#deckFullscreen");
  if (deckFull && stageEl) {
    deckFull.addEventListener("click", function () {
      if (document.fullscreenElement) {
        if (document.exitFullscreen) document.exitFullscreen();
      } else if (stageEl.requestFullscreen) {
        stageEl.requestFullscreen();
      }
    });
  }

  document.addEventListener("keydown", function (e) {
    if (document.fullscreenElement && (e.key === "ArrowLeft" || e.key === "ArrowRight")) {
      e.preventDefault();
      stepSlide(e.key === "ArrowRight" ? 1 : -1);
    }
  });


  /* ── Boot flash ───────────────────────────────────────────── */
  var bootScreen = $("#bootScreen");
  var bootDone = false;
  function dismissBoot() {
    if (!bootScreen || bootDone) return;
    bootDone = true;
    bootScreen.classList.add("is-done");
    window.setTimeout(function () { bootScreen.setAttribute("hidden", ""); }, 620);
  }
  if (bootScreen) {
    var scheduleBoot = function () { window.setTimeout(dismissBoot, 940); };
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", scheduleBoot);
    else scheduleBoot();
    window.addEventListener("load", function () { window.setTimeout(dismissBoot, 320); });
    window.setTimeout(dismissBoot, 3000);
  }

  /* ── OneDrive video preview modal ─────────────────────────── */
  var videoModal = $("#videoModal");
  var videoFrame = $("#videoFrame");
  var videoLoading = $("#videoLoading");
  var lastVideoFocus = null;
  var videoLoadTimer = null;
  function openVideo() {
    if (!videoModal) return;
    lastVideoFocus = document.activeElement;
    videoModal.classList.add("is-open");
    videoModal.setAttribute("aria-hidden", "false");
    document.body.style.overflow = "hidden";
    if (videoFrame) {
      if (videoLoading) videoLoading.hidden = false;
      var src = videoFrame.getAttribute("data-src");
      if (src) videoFrame.src = src;
      videoFrame.classList.remove("is-loaded");
      window.clearTimeout(videoLoadTimer);
      videoLoadTimer = window.setTimeout(function () {
        videoFrame.classList.add("is-loaded");
        if (videoLoading) videoLoading.hidden = true;
      }, 2600);
    }
    var close = $(".video-dialog-head .icon-btn", videoModal);
    if (close) close.focus();
  }
  function closeVideo() {
    if (!videoModal) return;
    videoModal.classList.remove("is-open");
    videoModal.setAttribute("aria-hidden", "true");
    document.body.style.overflow = "";
    window.clearTimeout(videoLoadTimer);
    if (videoFrame) videoFrame.src = "about:blank";
    if (lastVideoFocus && lastVideoFocus.focus) lastVideoFocus.focus();
  }
  $$("[data-video-open], #videoPoster").forEach(function (btn) {
    btn.addEventListener("click", openVideo);
  });
  if (videoModal) {
    $$("[data-video-close]", videoModal).forEach(function (btn) {
      btn.addEventListener("click", closeVideo);
    });
    if (videoFrame) {
      videoFrame.addEventListener("load", function () {
        if (!videoFrame.src || videoFrame.src === "about:blank") return;
        window.clearTimeout(videoLoadTimer);
        videoFrame.classList.add("is-loaded");
        if (videoLoading) videoLoading.hidden = true;
      });
    }
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && videoModal.classList.contains("is-open")) closeVideo();
    });
  }

  /* ── Boot ─────────────────────────────────────────────────── */
  var initialLang = SUPPORTED.indexOf(root.dataset.lang) >= 0 ? root.dataset.lang : "en";
  var initialTheme = root.dataset.theme === "light" ? "light" : "dark";
  applyTheme(initialTheme, { persist: false });
  applyLanguage(initialLang, { persist: false });
  showSlide(0, { instant: true });

  window.TF = { applyLanguage: applyLanguage, applyTheme: applyTheme, showSlide: showSlide };
})();
