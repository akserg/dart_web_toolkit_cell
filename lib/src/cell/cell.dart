//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell;

/**
 * A lightweight representation of a renderable object.
 * 
 * <p>
 * Multiple cell widgets or Columns can share a single Cell instance, but there
 * may be implications for certain stateful Cells. Generally, Cells are
 * stateless flyweights that see the world as row values/keys. If a Column
 * contains duplicate row values/keys, the Cell will not differentiate the value
 * in one row versus another. Similarly, if you use a single Cell instance in
 * multiple Columns, the Cells will not differentiate the values coming from one
 * Column versus another.
 * </p>
 * 
 * <p>
 * However, some interactive Cells ({@link EditTextCell}, {@link CheckboxCell},
 * {@link TextInputCell}, etc...) have a stateful "pending" state, which is a
 * map of row values/keys to the end user entered pending value. For example, if
 * an end user types a new value in a {@link TextInputCell}, the
 * {@link TextInputCell} maps the "pending value" and associates it with the
 * original row value/key. The next time the Cell Widget renders that row
 * value/key, the Cell renders the pending value instead. This allows
 * applications to refresh the Cell Widget without clearing out all of the end
 * user's pending changes. In subclass of {@link AbstractEditableCell}, the
 * pending state remains until either the original value is updated (a
 * successful commit), or until
 * {@link AbstractEditableCell#clearViewData(Object)} is called (a failed
 * commit).
 * </p>
 * 
 * <p>
 * If you share an interactive Cell between two cell widgets (or Columns within
 * the same CellTable), then when the end user updates the pending value in one
 * widget, it will be reflected in the other widget <i>when the other widget is
 * redrawn</i>. You should base your decision on whether or not to share Cell
 * instances on this behavior.
 * </p>
 * 
 * <p>
 * <h3>Example</h3>
 * {@example com.google.gwt.examples.cell.CellExample}
 * </p>
 * 
 * <p>
 * <span style="color:red;">Warning: The Cell interface may change in subtle but breaking ways as we
 * continuously seek to improve performance. You should always subclass {@link AbstractCell} instead
 * of implementing {@link Cell} directly.</span>
 * </p>
 * 
 * @param <C> the type that this Cell represents
 */
abstract class Cell<C> {

  /**
   * Check if this cell depends on the selection state.
   * 
   * @return true if dependent on selection, false if not
   */
  bool dependsOnSelection();

  /**
   * Get the set of events that this cell consumes (see
   * {@link com.google.gwt.dom.client.BrowserEvents BrowserEvents} for useful
   * constants). The container that uses this cell should only pass these events
   * to
   * {@link #onBrowserEvent(CellContext, Element, Object, NativeEvent, ValueUpdater)}
   * when the event occurs.
   * 
   * <p>
   * The returned value should not be modified, and may be an unmodifiable set.
   * Changes to the return value may not be reflected in the cell.
   * </p>
   * 
   * @return the consumed events, or null if no events are consumed
   * 
   * @see com.google.gwt.dom.client.BrowserEvents
   */
  Set<String> getConsumedEvents();

  /**
   * Check if this cell handles selection. If the cell handles selection, then
   * its container should not automatically handle selection.
   * 
   * @return true if the cell handles selection, false if not
   */
  bool handlesSelection();

  /**
   * Returns true if the cell is currently editing the data identified by the
   * given element and key. While a cell is editing, widgets containing the cell
   * may choose to pass keystrokes directly to the cell rather than using them
   * for navigation purposes.
   * 
   * @param context the {@link CellContext} of the cell
   * @param parent the parent Element
   * @param value the value associated with the cell
   * @return true if the cell is in edit mode
   */
  bool isEditing(CellContext context, dart_html.Element parent, C value);

  /**
   * Handle a browser event that took place within the cell. The default
   * implementation returns null.
   * 
   * @param context the {@link CellContext} of the cell
   * @param parent the parent Element
   * @param value the value associated with the cell
   * @param event the native browser event
   * @param valueUpdater a {@link ValueUpdater}, or null if not specified
   */
  void onBrowserEvent(CellContext context, dart_html.Element parent, C value, dart_html.Event event,
      ValueUpdater<C> valueUpdater);

  /**
   * Render a cell as HTML into a {@link SafeHtmlBuilder}, suitable for passing
   * to {@link Element#setInnerHTML(String)} on a container element.
   * 
   * <p>
   * Note: If your cell contains natively focusable elements, such as buttons or
   * input elements, be sure to set the tabIndex to -1 so that they do not steal
   * focus away from the containing widget.
   * </p>
   * 
   * @param context the {@link CellContext} of the cell
   * @param value the cell value to be rendered
   * @param sb the {@link SafeHtmlBuilder} to be written to
   */
  void render(CellContext context, C value, util.SafeHtmlBuilder sb);

  /**
   * Reset focus on the Cell. This method is called if the cell has focus when
   * it is refreshed.
   * 
   * @param context the {@link CellContext} of the cell
   * @param parent the parent Element
   * @param value the value associated with the cell
   * @return true if focus is taken, false if not
   */
  bool resetFocus(CellContext context, dart_html.Element parent, C value);

  /**
   * This method may be used by cell containers to set the value on a single
   * cell directly, rather than using {@link Element#setInnerHTML(String)}. See
   * {@link AbstractCell#setValue(CellContext, Element, Object)} for a default
   * implementation that uses {@link #render(CellContext, Object, SafeHtmlBuilder)}.
   * 
   * @param context the {@link CellContext} of the cell
   * @param parent the parent Element
   * @param value the value associated with the cell
   */
  void setValue(CellContext context, dart_html.Element parent, C value);
}

/**
 * Contains information about the context of the Cell.
 */
class CellContext {

  int _column;
  int index;
  Object key;
  int subindex;

  /**
   * Create a new {@link CellContext}.
   * 
   * @param index the absolute index of the value
   * @param column the column index of the cell, or 0
   * @param key the unique key that represents the row value
   * @param subindex the child index
   */
  CellContext(this.index, this._column, this.key, [this.subindex = 0]);

  /**
   * Get the column index of the cell. If the view only contains a single
   * column, this method returns 0.
   * 
   * @return the column index of the cell
   */
  int getColumn() {
    return _column;
  }

  /**
   * Get the absolute index of the value.
   * 
   * @return the index
   */
  int getIndex() {
    return index;
  }

  /**
   * Get the key that uniquely identifies the row object.
   * 
   * @return the unique key
   */
  Object getKey() {
    return key;
  }

  /**
   * Get the sub index of the rendered row value. If the row value renders to
   * a single row element, the sub index is 0. If the row value renders to
   * more than one row element, the sub index may be greater than zero.
   */
  int getSubIndex() {
    return subindex;
  }
}