// Documentation navigation hooks
const DocsNavigation = {
  mounted() {
    // Handle smooth scrolling when clicking on table of contents links
    this.handleEvent("scroll_to_section", ({ id }) => {
      const element = document.getElementById(id);
      if (element) {
        element.scrollIntoView({ 
          behavior: "smooth",
          block: "start"
        });
        
        // Add a highlight effect to the section
        element.classList.add("highlight-section");
        setTimeout(() => {
          element.classList.remove("highlight-section");
        }, 2000);
        
        // Update active link in table of contents
        this.updateActiveTocLink(id);
      }
    });
    
    // Set up intersection observer to track which section is currently in view
    this.setupSectionObserver();
  },
  
  updateActiveTocLink(id) {
    // Remove active class from all TOC links
    document.querySelectorAll('.toc-link').forEach(link => {
      link.classList.remove('toc-link-active');
    });
    
    // Add active class to the current link
    const activeLink = document.querySelector(`.toc-link[href="#${id}"]`);
    if (activeLink) {
      activeLink.classList.add('toc-link-active');
    }
  },
  
  setupSectionObserver() {
    // Get all headings in the content
    const headings = document.querySelectorAll('.static-content h3[id]');
    
    // Set up intersection observer options
    const options = {
      root: null, // viewport
      rootMargin: '-80px 0px -80% 0px', // Consider element in view when it's 80px from the top and not in the bottom 80%
      threshold: 0
    };
    
    // Create observer
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          // When a heading enters the viewport, update the active TOC link
          this.updateActiveTocLink(entry.target.id);
        }
      });
    }, options);
    
    // Observe all headings
    headings.forEach(heading => {
      observer.observe(heading);
    });
  }
};

export default DocsNavigation;
