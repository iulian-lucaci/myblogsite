// Google Consent Mode API handler
(function() {
  const CONSENT_KEY = 'google-consent-mode';
  const CONSENT_EXPIRY_DAYS = 365;

  // Initialize Consent Mode with default denied
  window.dataLayer = window.dataLayer || [];
  function gtag() { dataLayer.push(arguments); }

  // Set default consent state to denied
  gtag('consent', 'default', {
    'analytics_storage': 'denied',
    'ad_storage': 'denied',
    'ad_user_data': 'denied',
    'ad_personalization': 'denied'
  });

  // Check for stored consent preference
  function getSavedConsent() {
    const saved = localStorage.getItem(CONSENT_KEY);
    return saved ? JSON.parse(saved) : null;
  }

  // Save consent preference
  function saveConsent(granted) {
    const consent = {
      granted: granted,
      timestamp: new Date().toISOString(),
      expiry: new Date(Date.now() + CONSENT_EXPIRY_DAYS * 24 * 60 * 60 * 1000).toISOString()
    };
    localStorage.setItem(CONSENT_KEY, JSON.stringify(consent));
    return consent;
  }

  // Update Consent Mode
  function updateConsentMode(granted) {
    const status = granted ? 'granted' : 'denied';
    gtag('consent', 'update', {
      'analytics_storage': status,
      'ad_storage': status,
      'ad_user_data': status,
      'ad_personalization': status
    });
  }

  // Hide consent banner
  function hideBanner() {
    const banner = document.getElementById('consent-banner');
    if (banner) {
      banner.style.display = 'none';
    }
  }

  // Show consent banner
  function showBanner() {
    const banner = document.getElementById('consent-banner');
    if (banner) {
      banner.style.display = 'block';
    }
  }

  // Handle accept
  function handleAccept() {
    saveConsent(true);
    updateConsentMode(true);
    hideBanner();
    console.log('Consent: Analytics accepted');
  }

  // Handle reject
  function handleReject() {
    saveConsent(false);
    updateConsentMode(false);
    hideBanner();
    console.log('Consent: Analytics rejected');
  }

  // Initialize consent on page load
  function initConsent() {
    const saved = getSavedConsent();
    
    // Check if consent is still valid
    if (saved) {
      const expiryDate = new Date(saved.expiry);
      if (expiryDate > new Date()) {
        // Consent is still valid, apply it
        updateConsentMode(saved.granted);
        hideBanner();
        return;
      }
    }

    // No valid consent, show banner
    showBanner();
  }

  // Wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      initConsent();

      // Add event listeners
      const acceptBtn = document.getElementById('consent-accept');
      const rejectBtn = document.getElementById('consent-reject');

      if (acceptBtn) acceptBtn.addEventListener('click', handleAccept);
      if (rejectBtn) rejectBtn.addEventListener('click', handleReject);
    });
  } else {
    initConsent();

    const acceptBtn = document.getElementById('consent-accept');
    const rejectBtn = document.getElementById('consent-reject');

    if (acceptBtn) acceptBtn.addEventListener('click', handleAccept);
    if (rejectBtn) rejectBtn.addEventListener('click', handleReject);
  }
})();
