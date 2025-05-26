/**
 * LiveView Hooks for handling tab navigation validation
 */

const ValidationHooks = {
  // Form validation hook for description component
  FormValidation: {
    mounted() {
      this.updateValidationState();
      this.el.addEventListener("data-valid-changed", () => this.updateValidationState());
    },
    updated() {
      this.updateValidationState();
    },
    updateValidationState() {
      const isValid = this.el.dataset.valid === "true";
      // Push the validation state to the parent component
      this.pushEvent("update_validation_state", { component: "description", valid: isValid });
    }
  },
  
  // Photo selection validation hook
  PhotoValidation: {
    mounted() {
      this.updateValidationState();
      this.el.addEventListener("data-valid-changed", () => this.updateValidationState());
    },
    updated() {
      this.updateValidationState();
    },
    updateValidationState() {
      const isValid = this.el.dataset.valid === "true";
      // Push the validation state to the parent component
      this.pushEvent("update_validation_state", { component: "photo_selection", valid: isValid });
    }
  },
  
  // SNS selection validation hook
  SnsValidation: {
    mounted() {
      this.updateValidationState();
      this.el.addEventListener("data-valid-changed", () => this.updateValidationState());
    },
    updated() {
      this.updateValidationState();
    },
    updateValidationState() {
      const isValid = this.el.dataset.valid === "true";
      // Push the validation state to the parent component
      this.pushEvent("update_validation_state", { component: "sns_selection", valid: isValid });
    }
  }
};

export default ValidationHooks;
