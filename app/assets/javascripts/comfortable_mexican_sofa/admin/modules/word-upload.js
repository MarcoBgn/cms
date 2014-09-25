define('word-upload', [], function () {
  'use strict';
  return {
    init: function(options) {
      this.options = options;
      this.elements = {
        fileInputNode: options.fileInputNode,
        activateFileInputNode: options.activateFileInputNode,
        wordFormNode: options.wordFormNode
      }
      this.showConfirm = false;
      this.activateWordUploadForm = this.activateWordUploadForm.bind(this);
      this.submitWordUploadForm = this.submitWordUploadForm.bind(this);
      this.handleActivateNodeEvent = this.handleActivateNodeEvent.bind(this);
      this.setupEventListeners();
    },

    setupEventListeners: function() {
      this.elements.wordFormNode.addEventListener('change', this.submitWordUploadForm);
      this.elements.activateFileInputNode.addEventListener('click', this.handleActivateNodeEvent);
    },

    handleActivateNodeEvent: function(e) {
      if(e.type === 'keydown' && e.keyCode !== 13) return;
      this.activateWordUploadForm();
    },

    activateWordUploadForm: function() {
      this.elements.fileInputNode.click();
    },

    submitWordUploadForm: function() {
      if(this.showConfirm) {
        if(!confirm('Uploading a Word document will delete the current content. Are you sure you wish to continue?')) {
          this.elements.wordFormNode.reset();
          return;
        }
      }
      this.elements.wordFormNode.submit();
    }
  };
});
