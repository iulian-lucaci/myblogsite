// Theme Toggle Functionality
(function() {
  const THEME_KEY = 'site-theme';
  const THEME_LIGHT = 'light';
  const THEME_DARK = 'dark';

  // DOM elements
  const toggleBtn = document.getElementById('theme-toggle');
  const sunIcon = document.getElementById('theme-icon-sun');
  const moonIcon = document.getElementById('theme-icon-moon');

  // Get saved theme or default to light
  function getSavedTheme() {
    return localStorage.getItem(THEME_KEY) || THEME_LIGHT;
  }

  // Save theme preference
  function saveTheme(theme) {
    localStorage.setItem(THEME_KEY, theme);
  }

  // Apply theme to document
  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);

    // Update icon visibility
    if (theme === THEME_DARK) {
      sunIcon.style.display = 'none';
      moonIcon.style.display = 'block';
    } else {
      sunIcon.style.display = 'block';
      moonIcon.style.display = 'none';
    }
  }

  // Toggle theme
  function toggleTheme() {
    const currentTheme = getSavedTheme();
    const newTheme = currentTheme === THEME_LIGHT ? THEME_DARK : THEME_LIGHT;

    saveTheme(newTheme);
    applyTheme(newTheme);
  }

  // Initialize theme on page load
  function initTheme() {
    const savedTheme = getSavedTheme();
    applyTheme(savedTheme);
  }

  // Wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      initTheme();

      // Add event listener to toggle button
      if (toggleBtn) {
        toggleBtn.addEventListener('click', toggleTheme);
      }
    });
  } else {
    initTheme();

    if (toggleBtn) {
      toggleBtn.addEventListener('click', toggleTheme);
    }
  }

  // Optional: Detect system preference on first visit
  if (!localStorage.getItem(THEME_KEY)) {
    const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (prefersDark) {
      saveTheme(THEME_DARK);
      applyTheme(THEME_DARK);
    }
  }
})();
