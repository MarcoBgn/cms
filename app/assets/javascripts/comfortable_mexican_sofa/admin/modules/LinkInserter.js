define([
  'jquery',
  'DoughBaseComponent',
  'eventsWithPromises'
], function (
  $,
  DoughBaseComponent,
  eventsWithPromises
) {
  'use strict';

  var LinkInserterProto,
      defaultConfig = {
        selectors: {
          context: '[data-dough-linkinserter-context]',
          insertLink: '[data-dough-linkinserter-insertlink]',
          valueTrigger: '[data-dough-linkinserter-value-trigger]'
        },
        uiEvents: {

        }
      };

  function LinkInserter($el, config) {
    LinkInserter.baseConstructor.call(this, $el, config, defaultConfig);
    this.link = null;
    this.context = this.$el.attr(this._stripSquareBrackets(this.config.selectors.context));
  }

  DoughBaseComponent.extend(LinkInserter);

  LinkInserterProto = LinkInserter.prototype;

  LinkInserterProto.init = function(initialised) {
    this._cacheComponentElements();
    this._setupUIEvents();
    this._initialisedSuccess(initialised);
  };

  LinkInserterProto._cacheComponentElements = function() {
    this.$insertLinks = this.$el.find(this.config.selectors.insertLink);
    this.$valueTriggers = this.$el.find(this.config.selectors.valueTrigger);
  };

  LinkInserterProto._handleFormControlUpdate = function(e) {
    this.setLink($(e.target).val());
  };

  LinkInserterProto._setupUIEvents = function() {
    this.$el
      .on('input', '[data-dough-linkinserter-value-trigger][type="text"]', $.proxy(this._handleFormControlUpdate, this))
      .on('keyup', '[data-dough-linkinserter-value-trigger][type="text"]', $.proxy(this._handleFormControlUpdate, this))
      .on('change', '[data-dough-linkinserter-value-trigger][type="radio"]', $.proxy(this._handleFormControlUpdate, this))
      .on('click', '[data-dough-linkinserter-insertlink]', $.proxy(this.publishLink, this));
  };

  LinkInserterProto._stripSquareBrackets = function(str) {
    return str.replace(/([\[\]])+/gi,'');
  };

  LinkInserterProto.setLink = function(link) {
    if(!link) return;
    this.link = link;
  };

  LinkInserterProto.publishLink = function() {
    eventsWithPromises.publish('linkinserter:link-published', {
      emitter: this.context,
      link: this.link
    });
  };

  return LinkInserter;
});
