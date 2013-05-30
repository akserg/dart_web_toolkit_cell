//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_view;

/**
 * Standard implementation used by most cell based widgets.
 */
class CellBasedWidgetImplStandard extends CellBasedWidgetImpl {

  /**
   * The method used to dispatch non-bubbling events.
   */
  static Function dispatchNonBubblingEvent;

  /**
   * Dispatch an event through the normal GWT mechanism.
   */
  static void dispatchEvent(dart_html.Event evt, dart_html.Element elem, event.EventListener listener) {
    //@com.google.gwt.user.client.DOM::dispatchEvent(Lcom/google/gwt/user/client/event.Event;Lcom/google/gwt/user/client/dart_html.Element;Lcom/google/gwt/user/client/event.EventListener;)(evt, elem, listener);
    event.Dom.dispatchEvent(evt, elem, listener);
  }

  /**
   * Handle an event from a cell. Used by {@link #_initEventSystem()}.
   * 
   * @param event the event to handle.
   */
  static void _handleNonBubblingEvent(dart_html.Event evt) {
    // Get the evt target.
    dart_html.EventTarget eventTarget = evt.target; //getEventTarget();
    if (!(eventTarget is dart_html.Element)) {
      return;
    }
    dart_html.Element target = eventTarget as dart_html.Element;

    // Get the evt listener, which is the first widget that handles the
    // specified evt type.
    String typeName = evt.type;
    event.EventListener listener = event.Dom.getEventListener(target);
    while (target != null && listener == null) {
      target = target.parent;
      if (target != null && _isNonBubblingEventHandled(target, typeName)) {
        // The target handles the evt, so this must be the evt listener.
        listener = event.Dom.getEventListener(target);
      }
    }

    // Fire the evt.
    if (listener != null) {
      dispatchEvent(evt, target, listener);
    }
  }

  /**
   * Check if the specified element handles the a non-bubbling event.
   * 
   * @param elem the element to check
   * @param typeName the non-bubbling event
   * @return true if the event is handled, false if not
   */
  static bool _isNonBubblingEventHandled(dart_html.Element elem, String typeName) {
    //return "true".equals(elem.getAttribute("__gwtCellBasedWidgetImplDispatching" + typeName));
    return elem.attributes["__gwtCellBasedWidgetImplDispatching" + typeName] == "true";
  }

  /**
   * The set of non bubbling event types.
   */
  final Set<String> _nonBubblingEvents = new Set<String>();

  CellBasedWidgetImplStandard() {
    // Initialize the set of non-bubbling events.
    _nonBubblingEvents.add(event.BrowserEvents.FOCUS);
    _nonBubblingEvents.add(event.BrowserEvents.BLUR);
    _nonBubblingEvents.add(event.BrowserEvents.LOAD);
    _nonBubblingEvents.add(event.BrowserEvents.ERROR);
  }

  int sinkEvent(ui.Widget widget, String typeName) {
    if (_nonBubblingEvents.contains(typeName)) {
      // Initialize the event system.
      if (dispatchNonBubblingEvent == null) {
        _initEventSystem();
      }

      // Sink the non-bubbling event.
      dart_html.Element elem = widget.getElement();
      if (!_isNonBubblingEventHandled(elem, typeName)) {
        //elem.setAttribute("__gwtCellBasedWidgetImplDispatching" + typeName, "true");
        elem.attributes["__gwtCellBasedWidgetImplDispatching" + typeName] = "true";
        _sinkEventImpl(elem, typeName);
      }
      return -1;
    } else {
      return super.sinkEvent(widget, typeName);
    }
  }

  /**
   * Initialize the event system.
   */
  void _initEventSystem() {
//    @com.google.gwt.user.cellview.client.CellBasedWidgetImplStandard::dispatchNonBubblingEvent = $entry(function(evt) {
//      @com.google.gwt.user.cellview.client.CellBasedWidgetImplStandard::_handleNonBubblingEvent(Lcom/google/gwt/user/client/event.Event;)(evt);
//    });
    CellBasedWidgetImplStandard.dispatchNonBubblingEvent = (dart_html.Event evt) {
      CellBasedWidgetImplStandard._handleNonBubblingEvent(evt);
    };
  }

  /**
   * Sink an event on the element.
   * 
   * @param elem the element to sink the event on
   * @param typeName the name of the event to sink
   */
  void _sinkEventImpl(dart_html.Element elem, String typeName) {
    //elem.addEventListener(typeName, @com.google.gwt.user.cellview.client.CellBasedWidgetImplStandard::dispatchNonBubblingEvent, true);
  }
}