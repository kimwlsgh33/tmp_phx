/**
 * SettingsStorage Hook
 * 
 * Provides local storage functionality for dashboard advanced settings
 * Persists settings across page refreshes and browser sessions
 */
const SettingsStorage = {
  mounted() {
    // Listen for save settings event from LiveView
    this.handleEvent("save_settings", ({ key, value }) => {
      console.log("[SettingsStorage] Saving settings to localStorage:", key);
      localStorage.setItem(key, value);
    });

    // Listen for load settings event from LiveView
    this.handleEvent("load_settings", ({ key }) => {
      console.log("[SettingsStorage] Loading settings from localStorage:", key);
      const savedSettings = localStorage.getItem(key);
      
      if (savedSettings) {
        // Send saved settings back to LiveView
        this.pushEvent("settings_loaded", { value: savedSettings });
      }
    });
  }
};

export default SettingsStorage;
