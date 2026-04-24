/**
 * main.js — Noor Companion landing page interactions
 * Handles smooth scroll, nav shrink on scroll, and store link placeholders
 */

(function () {
  'use strict';

  /** Shrinks the nav slightly when the user scrolls past the hero */
  function initNavScroll() {
    const nav = document.querySelector('.nav');
    if (!nav) return;

    window.addEventListener('scroll', function () {
      if (window.scrollY > 40) {
        nav.classList.add('nav--scrolled');
      } else {
        nav.classList.remove('nav--scrolled');
      }
    }, { passive: true });
  }

  /** Prevents dead-link navigation on store buttons during pre-launch */
  function initStoreLinks() {
    document.querySelectorAll('[data-store-link]').forEach(function (el) {
      el.addEventListener('click', function (e) {
        const href = el.getAttribute('href');
        if (!href || href === '#') {
          e.preventDefault();
          showComingSoonToast(el.dataset.storeLink);
        }
      });
    });
  }

  /** Shows a brief toast message */
  function showComingSoonToast(store) {
    const existing = document.getElementById('nc-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.id = 'nc-toast';
    toast.textContent = store === 'ios'
      ? 'Coming soon to the App Store'
      : 'Coming soon to Google Play';
    toast.style.cssText = [
      'position:fixed',
      'bottom:32px',
      'left:50%',
      'transform:translateX(-50%)',
      'background:#1A1A2E',
      'color:#fff',
      'padding:12px 24px',
      'border-radius:50px',
      'font-size:0.9rem',
      'font-weight:500',
      'box-shadow:0 8px 32px rgba(0,0,0,0.2)',
      'z-index:9999',
      'white-space:nowrap',
      'animation:toastIn 0.25s ease',
    ].join(';');

    const style = document.createElement('style');
    style.textContent = '@keyframes toastIn{from{opacity:0;transform:translateX(-50%) translateY(12px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}';
    document.head.appendChild(style);
    document.body.appendChild(toast);

    setTimeout(function () {
      toast.style.opacity = '0';
      toast.style.transition = 'opacity 0.3s ease';
      setTimeout(function () { toast.remove(); }, 300);
    }, 2800);
  }

  /** Animates feature cards into view when they enter the viewport */
  function initScrollReveal() {
    if (!window.IntersectionObserver) return;

    const targets = document.querySelectorAll('[data-reveal]');

    const observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('revealed');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12 });

    targets.forEach(function (el) { observer.observe(el); });
  }

  document.addEventListener('DOMContentLoaded', function () {
    initNavScroll();
    initStoreLinks();
    initScrollReveal();
  });
}());
