//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_view;

/**
 * Implementation used by various cell based widgets.
 */
abstract class CellBasedWidgetImpl {

  /**
   * The singleton impl instance.
   */
  static CellBasedWidgetImpl _impl;

  /**
   * Get the singleton instance.
   *
   * @return the {@link CellBasedWidgetImpl} instance
   */
  static CellBasedWidgetImpl get() {
    if (_impl == null) {
      _impl = new CellBasedWidgetImpl.browserDependent();//GWT.create(CellBasedWidgetImpl.class);
    }
    return _impl;
  }

  /**
   * Create instance of [CellBasedWidgetImpl] depends on broswer.
   */
  factory CellBasedWidgetImpl.browserDependent() {
    return new CellBasedWidgetImplStandard();
  }
  
  /**
   * The set of natively focusable elements.
   */
  Set<String> focusableTypes;

  CellBasedWidgetImpl() {
    focusableTypes = new Set<String>();
    focusableTypes.add("select");
    focusableTypes.add("input");
    focusableTypes.add("textarea");
    focusableTypes.add("option");
    focusableTypes.add("button");
    focusableTypes.add("label");
  }

  /**
   * Check if an element is focusable. If an element is focusable, the cell
   * widget should not steal focus from it.
   * 
   * @param elem the element
   * @return true if the element is focusable, false if not
   */
  bool isFocusable(dart_html.Element elem) {
    return focusableTypes.contains(elem.tagName.toLowerCase())
        || elem.tabIndex() >= 0;
  }

  /**
   * Process an event on a target cell.
   *
   * @param widget the {@link ui.Widget} on which the event occurred
   * @param event the event to handle
   */
  void onBrowserEvent(ui.Widget widget, event.Event event) {
  }

  /**
   * Takes in an html string and processes it, adding support for events.
   *
   * @param html the html string to process
   * @return the processed html string
   */
  util.SafeHtml processHtml(util.SafeHtml html) {
    return html;
  }

  /**
   * Reset focus on an element.
   *
   * @param command the command to execute when resetting focus
   */
  void resetFocus(scheduler.ScheduledCommand command) {
    command.execute();
  }

  /**
   * Sink events on the widget.
   *
   * @param widget the {@link ui.Widget} that will handle the events
   * @param typeNames the names of the events to sink
   */
  void sinkEvents(ui.Widget widget, Set<String> typeNames) {
    if (typeNames == null) {
      return;
    }

    int eventsToSink = 0;
    for (String typeName in typeNames) {
      int typeInt = event.IEvent.getTypeInt(typeName);
      if (typeInt < 0) {
        widget.sinkBitlessEvent(typeName);
      } else {
        typeInt = sinkEvent(widget, typeName);
        if (typeInt > 0) {
          eventsToSink |= typeInt;
        }
      }
    }
    if (eventsToSink > 0) {
      widget.sinkEvents(eventsToSink);
    }
  }

  /**
   * Get the event bits to sink for an event type.
   *
   * @param widget the {@link ui.Widget} that will handle the events
   * @param typeName the name of the event to sink
   * @return the event bits to sink, or -1 if no events to sink
   */
  int sinkEvent(ui.Widget widget, String typeName) {
    return event.IEvent.getTypeInt(typeName);
  }
}