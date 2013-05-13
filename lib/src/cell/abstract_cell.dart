//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell;

/**
 * A default implementation of the {@link Cell} interface.
 * 
 * <p>
 * <h3>Examples</h3>
 * <dl>
 * <dt>Read only cell</dt>
 * <dd>{@example com.google.gwt.examples.cell.CellExample}</dd>
 * <dt>Cell with events</dt>
 * <dd>{@example com.google.gwt.examples.cell.CellWithEventsExample}</dd>
 * <dt>Interactive cell</dt>
 * <dd>{@example com.google.gwt.examples.cell.InteractionCellExample}</dd>
 * <dt>Editable cell</dt>
 * <dd>{@example com.google.gwt.examples.cell.EditableCellExample}</dd>
 * </dl>
 * </p>
 * 
 * @param <C> the type that this Cell represents
 */
abstract class AbstractCell<C> implements Cell<C> {

  /**
   * The unmodifiable set of events consumed by this cell.
   */
  Set<String> _consumedEvents;

  /**
   * Construct a new {@link AbstractCell} with the specified consumed events.
   * The input arguments are passed by copy.
   * 
   * @param consumedEvents the {@link com.google.gwt.dom.client.BrowserEvents
   *          events} that this cell consumes
   * 
   * @see com.google.gwt.dom.client.BrowserEvents
   */
  AbstractCell(List<String> consumedEvents) {
    Set<String> events = null;
    if (_consumedEvents != null && _consumedEvents.length > 0) {
      events = new Set<String>();
      for (String event in consumedEvents) {
        events.add(event);
      }
    }
    _init(events);
  }

  bool dependsOnSelection() {
    return false;
  }

  Set<String> getConsumedEvents() {
    return _consumedEvents;
  }

  bool handlesSelection() {
    return false;
  }

  /**
   * Returns false. Subclasses that support editing should override this method
   * to return the current editing status.
   */
  bool isEditing(CellContext context, dart_html.Element parent, C value) {
    return false;
  }

  /**
   * {@inheritDoc}
   * 
   * <p>
   * If you override this method to add support for events, remember to pass the
   * event types that the cell expects into the constructor.
   * </p>
   */
  void onBrowserEvent(CellContext context, dart_html.Element parent, C value,
      dart_html.Event evt, ValueUpdater<C> valueUpdater) {
    // Special case the ENTER key for a unified user experience.
    if (evt is dart_html.KeyboardEvent && (evt as dart_html.KeyboardEvent).keyCode == event.KeyCodes.KEY_ENTER) {
      onEnterKeyDown(context, parent, value, evt, valueUpdater);
    }
  }

  void render(CellContext context, C value, util.SafeHtmlBuilder sb);

  /**
   * {@inheritDoc}
   * 
   * <p>
   * This method is a no-op and returns false. If your cell is editable or can
   * be focused by the user, override this method to reset focus when the
   * containing widget is refreshed.
   * </p>
   */
  bool resetFocus(CellContext context, dart_html.Element parent, C value) {
    return false;
  }

  void setValue(CellContext context, dart_html.Element parent, C value) {
    util.SafeHtmlBuilder sb = new util.SafeHtmlBuilder();
    render(context, value, sb);
    //parent.setInnerSafeHtml(sb.toSafeHtml());
    parent.innerHtml = sb.toSafeHtml().asString();
  }

  /**
   * Called when the user triggers a <code>keydown</code> event with the ENTER
   * key while focused on the cell. If your cell interacts with the user, you
   * should override this method to provide a consistent user experience. Your
   * widget must consume <code>keydown</code> events for this method to be
   * called.
   * 
   * @param context the {@link CellContext} of the cell
   * @param parent the parent Element
   * @param value the value associated with the cell
   * @param event the native browser event
   * @param valueUpdater a {@link ValueUpdater}, or null if not specified
   */
  void onEnterKeyDown(CellContext context, dart_html.Element parent, C value,
      dart_html.Event event, ValueUpdater<C> valueUpdater) {
  }

  /**
   * Initialize the cell.
   * 
   * @param consumedEvents the events that the cell consumes
   */
  void _init(Set<String> consumedEvents) {
    if (consumedEvents != null) {
      //this._consumedEvents = Collections.unmodifiableSet(consumedEvents);
      this._consumedEvents = new Set.from(consumedEvents);
    }
  }
}