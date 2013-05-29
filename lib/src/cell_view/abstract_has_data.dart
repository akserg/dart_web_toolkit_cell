//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_view;

/**
 * An abstract {@link Widget} that implements {@link HasData}.
 * 
 * @param <T> the data type of each row
 */
abstract class AbstractHasData<T> extends ui.Composite implements HasData<T>,
    HasKeyProvider<T>, event.Focusable, HasKeyboardPagingPolicy {

  /**
   * The temporary element use to convert HTML to DOM.
   */
  static dart_html.Element _tmpElem;

  /**
   * Convenience method to convert the specified HTML into DOM elements and
   * return the parent of the DOM elements.
   * 
   * @param html the HTML to convert
   * @param tmpElem a temporary element
   * @return the parent element
   */
  static dart_html.Element convertToElementsInWidget(ui.Widget widget, dart_html.Element tmpElem,
      util.SafeHtml html) {
    // Attach an event listener so we can catch synchronous load events from
    // cached images.
    event.Dom.setEventListener(tmpElem, widget);

    tmpElem.innerHtml = html.asString();

    // Detach the event listener.
    event.Dom.setEventListener(tmpElem, null);

    return tmpElem;
  }

  /**
   * Convenience method to replace all children of a Widget.
   * 
   * @param widget the widget who's contents will be replaced
   * @param childContainer the container that holds the contents
   * @param html the html to set
   */
  static void replaceAllChildrenInWidgte(ui.Widget widget, dart_html.Element childContainer, util.SafeHtml html) {
    // If the widget is not attached, attach an event listener so we can catch
    // synchronous load events from cached images.
    if (!widget.isAttached()) {
      event.Dom.setEventListener(widget.getElement(), widget);
    }

    // Render the HTML.
    childContainer.innerHtml = CellBasedWidgetImpl.get().processHtml(html).asString();

    // Detach the event listener.
    if (!widget.isAttached()) {
      event.Dom.setEventListener(widget.getElement(), null);
    }
  }

  /**
   * Convenience method to convert the specified HTML into DOM elements and
   * replace the existing elements starting at the specified index. If the
   * number of children specified exceeds the existing number of children, the
   * remaining children should be appended.
   * 
   * @param widget the widget who's contents will be replaced
   * @param childContainer the container that holds the contents
   * @param newChildren an element containing the new children
   * @param start the start index to replace
   * @param html the HTML to convert
   */
  static void replaceChildrenInWidget(ui.Widget widget, dart_html.Element childContainer, dart_html.Element newChildren,
      int start, util.SafeHtml html) {
    // Get the first element to be replaced.
    int childCount = childContainer.getChildCount();
    dart_html.Element toReplace = null;
    if (start < childCount) {
      toReplace = childContainer.children[start];
    }

    // Replace the elements.
    int count = newChildren.$dom_childElementCount;
    for (int i = 0; i < count; i++) {
      if (toReplace == null) {
        // The child will be removed from tmpElem, so always use index 0.
         childContainer.append(newChildren.getChild(0));
      } else {
        dart_html.Element nextSibling = toReplace.nextElementSibling;
        newChildren.$dom_firstChild.replaceWith(toReplace);
        toReplace = nextSibling;
      }
    }
  }

  /**
   * Return the temporary element used to create elements.
   */
  static dart_html.Element _getTmpElem() {
    if (_tmpElem == null) {
      _tmpElem = new dart_html.DivElement(); //Document.get().createDivElement().cast();
    }
    return _tmpElem;
  }

  /**
   * A bool indicating that the widget has focus.
   */
  bool isFocused = false;

  int _accessKey = 0;

  /**
   * A bool indicating that the widget is refreshing, so all events should be
   * ignored.
   */
  bool isRefreshing = false;

  HasDataPresenter<T> _presenter;
  event.HandlerRegistration _keyboardSelectionReg;
  event.HandlerRegistration _selectionManagerReg;
  int _tabIndex = 0;

  /**
   * Constructs an {@link AbstractHasData} with the given page size.
   * 
   * @param elem the parent {@link Element}
   * @param pageSize the page size
   * @param keyProvider the key provider, or null
   */
  AbstractHasData.fromElement(dart_html.Element elem, int pageSize, data.ProvidesKey<T> keyProvider): this(new _Widget.fromElement(elem), pageSize, keyProvider);

  /**
   * Constructs an {@link AbstractHasData} with the given page size.
   * 
   * @param widget the parent {@link Widget}
   * @param pageSize the page size
   * @param keyProvider the key provider, or null
   */
  AbstractHasData(ui.Widget widget, int pageSize, data.ProvidesKey<T> keyProvider) {
    initWidget(widget);
    this._presenter = new HasDataPresenter<T>(this, new View<T>(this), pageSize, keyProvider);

    // Sink events.
    Set<String> eventTypes = new Set<String>();
    eventTypes.add(event.BrowserEvents.FOCUS);
    eventTypes.add(event.BrowserEvents.BLUR);
    eventTypes.add(event.BrowserEvents.KEYDOWN); // Used for keyboard navigation.
    eventTypes.add(event.BrowserEvents.KEYUP); // Used by subclasses for selection.
    eventTypes.add(event.BrowserEvents.CLICK); // Used by subclasses for selection.
    eventTypes.add(event.BrowserEvents.MOUSEDOWN); // No longer used, but here for legacy support.
    CellBasedWidgetImpl.get().sinkEvents(this, eventTypes);

    // Add a default selection event manager.
    _selectionManagerReg =
        addCellPreviewHandler(DefaultSelectionEventManager.createDefaultManager());

    // Add a default keyboard selection handler.
    setKeyboardSelectionHandler(new DefaultKeyboardSelectionHandler<T>(this));
  }

  
  event.HandlerRegistration addCellPreviewHandler(CellPreviewEventHandler<T> handler) {
    return _presenter.addCellPreviewHandler(handler);
  }

  /**
   * Add a {@link LoadingStateChangeEvent.Handler} to be notified of changes in
   * the loading state.
   * 
   * @param handler the handle
   * @return the registration for the handler
   */
  event.HandlerRegistration addLoadingStateChangeHandler(LoadingStateChangeEventHandler handler) {
    return _presenter.addLoadingStateChangeHandler(handler);
  }

  
  event.HandlerRegistration addRangeChangeHandler(RangeChangeEventHandler handler) {
    return _presenter.addRangeChangeHandler(handler);
  }

  
  event.HandlerRegistration addRowCountChangeHandler(RowCountChangeEventHandler handler) {
    return _presenter.addRowCountChangeHandler(handler);
  }

  /**
   * Get the access key.
   * 
   * @return the access key, or -1 if not set
   * @see #setAccessKey(int)
   */
  int getAccessKey() {
    return _accessKey;
  }

  /**
   * Get the row value at the specified visible index. Index 0 corresponds to
   * the first item on the page.
   * 
   * @param indexOnPage the index on the page
   * @return the row value
   * @deprecated use {@link #getVisibleItem(int)} instead
   */
//  @Deprecated
//  T getDisplayedItem(int indexOnPage) {
//    return getVisibleItem(indexOnPage);
//  }

  /**
   * Return the row values that the widget is currently displaying as an
   * immutable list.
   * 
   * @return a List of displayed items
   * @deprecated use {@link #getVisibleItems()} instead
   */
//  @Deprecated
//  List<T> getDisplayedItems() {
//    return getVisibleItems();
//  }

  
  KeyboardPagingPolicy getKeyboardPagingPolicy() {
    return _presenter.getKeyboardPagingPolicy();
  }

  /**
   * Get the index of the row that is currently selected via the keyboard,
   * relative to the page start index.
   * 
   * <p>
   * This is not same as the selected row in the {@link SelectionModel}. The
   * keyboard selected row refers to the row that the user navigated to via the
   * keyboard or mouse.
   * </p>
   * 
   * @return the currently selected row, or -1 if none selected
   */
  int getKeyboardSelectedRow() {
    return _presenter.getKeyboardSelectedRow();
  }

  
  KeyboardSelectionPolicy getKeyboardSelectionPolicy() {
    return _presenter.getKeyboardSelectionPolicy();
  }

  
  data.ProvidesKey<T> getKeyProvider() {
    return _presenter.getKeyProvider();
  }

  /**
   * Return the range size.
   * 
   * @return the size of the range as an int
   * 
   * @see #getVisibleRange()
   * @see #setPageSize(int)
   */
  int getPageSize() {
    return getVisibleRange().getLength();
  }

  /**
   * Return the range start.
   * 
   * @return the start of the range as an int
   * 
   * @see #getVisibleRange()
   * @see #setPageStart(int)
   */
  int getPageStart() {
    return getVisibleRange().getStart();
  }

  /**
   * Return the outer element that contains all of the rendered row values. This
   * method delegates to {@link #getChildContainer()};
   * 
   * @return the {@link dart_html.Element} that contains the rendered row values
   */
  dart_html.Element getRowContainer() {
    _presenter.flush();
    return getChildContainer();
  }

  
  int getRowCount() {
    return _presenter.getRowCount();
  }

  
  SelectionModel<T> getSelectionModel() {
    return _presenter.getSelectionModel();
  }

  
  int getTabIndex() {
    return _tabIndex;
  }

  /**
   * Get the key for the specified value. If a keyProvider is not specified or the value is null,
   * the value is returned. If the key provider is specified, it is used to get the key from
   * the value.
   * 
   * @param value the value
   * @return the key
   */
  Object getValueKey(T value) {
    data.ProvidesKey<T> keyProvider = getKeyProvider();
    return (keyProvider == null || value == null) ? value : keyProvider.getKey(value);
  }
  
  
  T getVisibleItem(int indexOnPage) {
    checkRowBounds(indexOnPage);
    return _presenter.getVisibleItem(indexOnPage);
  }

  
  int getVisibleItemCount() {
    return _presenter.getVisibleItemCount();
  }

  /**
   * Return the row values that the widget is currently displaying as an
   * immutable list.
   * 
   * @return a List of displayed items
   */
  
  List<T> getVisibleItems() {
    return _presenter.getVisibleItems();
  }

  
  Range getVisibleRange() {
    return _presenter.getVisibleRange();
  }

  
  bool isRowCountExact() {
    return _presenter.isRowCountExact();
  }

  /**
   * Handle browser events. Subclasses should override
   * {@link #onBrowserEvent2(Event)} if they want to extend browser event
   * handling.
   * 
   * @see #onBrowserEvent2(Event)
   */
  
  void onBrowserEvent(dart_html.Event evt) {
    CellBasedWidgetImpl.get().onBrowserEvent(this, evt);

    // Ignore spurious events (such as onblur) while we refresh the table.
    if (isRefreshing) {
      return;
    }

    // Verify that the target is still a child of this widget. IE fires focus
    // events even after the element has been removed from the DOM.
    dart_html.EventTarget eventTarget = evt.target;
    if (!(eventTarget is dart_html.Element)) {
      return;
    }
    dart_html.Element target = eventTarget as dart_html.Element;
    if (!(event.Dom.isOrHasChild(getElement(), target))) {
      return;
    }
    super.onBrowserEvent(evt);

    String eventType = evt.type;
    if (event.BrowserEvents.FOCUS == eventType) {
      // Remember the focus state.
      isFocused = true;
      onFocus();
    } else if (event.BrowserEvents.BLUR == eventType) {
      // Remember the blur state.
      isFocused = false;
      onBlur();
    } else if (event.BrowserEvents.KEYDOWN == eventType) {
      // A key event indicates that we already have focus.
      isFocused = true;
    } else if (event.BrowserEvents.MOUSEDOWN == eventType
        && CellBasedWidgetImpl.get().isFocusable(target)) {
      // If a natively focusable element was just clicked, then we must have
      // focus.
      isFocused = true;
    }

    // Let subclasses handle the event now.
    onBrowserEvent2(evt);
  }

  /**
   * Redraw the widget using the existing data.
   */
  void redraw() {
    _presenter.redraw();
  }

  /**
   * Redraw a single row using the existing data.
   * 
   * @param absRowIndex the absolute row index to redraw
   */
  void redrawRow(int absRowIndex) {
    int relRowIndex = absRowIndex - getPageStart();
    checkRowBounds(relRowIndex);
    setRowData(Collections.singletonList(getVisibleItem(relRowIndex)), absRowIndex);
  }

  /**
   * {@inheritDoc}
   * 
   * @see #getAccessKey()
   */
  
  void setAccessKey(int key) {
    this._accessKey = key;
    setKeyboardSelected(getKeyboardSelectedRow(), true, false);
  }

  
  void setFocus(bool focused) {
    dart_html.Element elem = getKeyboardSelectedElement();
    if (elem != null) {
      if (focused) {
        elem.focus();
      } else {
        elem.blur();
      }
    }
  }

  
  void setKeyboardPagingPolicy(KeyboardPagingPolicy policy) {
    _presenter.setKeyboardPagingPolicy(policy);
  }

  /**
   * Set the keyboard selected row and optionally focus on the new row.
   * 
   * @param row the row index relative to the page start
   * @param stealFocus true to focus on the new row
   * @see #setKeyboardSelectedRow(int)
   */
  void setKeyboardSelectedRow(int row, [bool stealFocus = true]) {
    _presenter.setKeyboardSelectedRow(row, stealFocus, true);
  }

  /**
   * Set the handler that handles keyboard selection/navigation.
   */
  void setKeyboardSelectionHandler(CellPreviewEventHandler<T> keyboardSelectionReg) {
    // Remove the old manager.
    if (this._keyboardSelectionReg != null) {
      this._keyboardSelectionReg.removeHandler();
      this._keyboardSelectionReg = null;
    }

    // Add the new manager.
    if (keyboardSelectionReg != null) {
      this._keyboardSelectionReg = addCellPreviewHandler(keyboardSelectionReg);
    }
  }

  
  void setKeyboardSelectionPolicy(KeyboardSelectionPolicy policy) {
    _presenter.setKeyboardSelectionPolicy(policy);
  }

  /**
   * Set the number of rows per page and refresh the view.
   * 
   * @param pageSize the page size
   * @see #setVisibleRange(Range)
   * @see #getPageSize()
   */
  void setPageSize(int pageSize) {
    setVisibleRange(getPageStart(), pageSize);
  }

  /**
   * Set the starting index of the current visible page. The actual page start
   * will be clamped in the range [0, getSize() - 1].
   * 
   * @param pageStart the index of the row that should appear at the start of
   *          the page
   * @see #setVisibleRange(Range)
   * @see #getPageStart()
   */
  void setPageStart(int pageStart) {
    setVisibleRange(pageStart, getPageSize());
  }

  void setRowCount(int size, [bool isExact = true]) {
    _presenter.setRowCount(size, isExact);
  }

  /**
   * <p>
   * Set the complete list of values to display on one page.
   * </p>
   * <p>
   * Equivalent to calling {@link #setRowCount(int)} with the length of the list
   * of values, {@link #setVisibleRange(Range)} from 0 to the size of the list
   * of values, and {@link #setRowData(int, List)} with a start of 0 and the
   * specified list of values.
   * </p>
   * 
   * @param values
   */
  void setRowData(List<T> values, [int start = null]) {
    if (start != null) {
      _presenter.setRowData(start, values);
    } else {
      setRowCount(values.length);
      setVisibleRange(new Range(0, values.length));
      setRowData(values, 0);
    }
  }

  /**
   * Set the {@link SelectionModel} that defines which items are selected and
   * the {@link com.google.gwt.view.client.CellPreviewEventHandler} that
   * controls how user selection is handled.
   * 
   * @param selectionModel the {@link SelectionModel} that defines selection
   * @param selectionEventManager the handler that controls user selection
   */
  void setSelectionModel(SelectionModel<T> selectionModel,
      [CellPreviewEventHandler<T> selectionEventManager = null]) {
    if (selectionEventManager != null) {
      // Remove the old manager.
      if (this._selectionManagerReg != null) {
        this._selectionManagerReg.removeHandler();
        this._selectionManagerReg = null;
      }
  
      // Add the new manager.
      if (selectionEventManager != null) {
        this._selectionManagerReg = addCellPreviewHandler(selectionEventManager);
      }
    }
    // Set the selection model.
    _presenter.setSelectionModel(selectionModel);
  }

  
  void setTabIndex(int index) {
    this._tabIndex = index;
    setKeyboardSelected(getKeyboardSelectedRow(), true, false);
  }
  
  void setVisibleRange(Range range) {
    _presenter.setVisibleRangeByRange(range);
  }
  
  void setVisibleRangeAndClearData(Range range, bool forceRangeChangeEvent) {
    _presenter.setVisibleRangeAndClearData(range, forceRangeChangeEvent);
  }

  /**
   * Check if a cell consumes the specified event type.
   * 
   * @param cell the cell
   * @param eventType the event type to check
   * @return true if consumed, false if not
   */
  bool cellConsumesEventType(Cell<T> cell, String eventType) {
    Set<String> consumedEvents = cell.getConsumedEvents();
    return consumedEvents != null && consumedEvents.contains(eventType);
  }

  /**
   * Check that the row is within the correct bounds.
   * 
   * @param row row index to check
   * @throws IndexOutOfBoundsException
   */
  void checkRowBounds(int row) {
    if (!isRowWithinBounds(row)) {
      throw new IndexOutOfBoundsException("Row index: " + row + ", Row size: " + getRowCount());
    }
  }

  /**
   * Convert the specified HTML into DOM elements and return the parent of the
   * DOM elements.
   * 
   * @param html the HTML to convert
   * @return the parent element
   */
  dart_html.Element convertToElements(util.SafeHtml html) {
    return convertToElements(this, _getTmpElem(), html);
  }

  /**
   * Check whether or not the cells in the view depend on the selection state.
   * 
   * @return true if cells depend on selection, false if not
   */
  bool dependsOnSelection();

  /**
   * Return the element that holds the rendered cells.
   * 
   * @return the container {@link dart_html.Element}
   */
  dart_html.Element getChildContainer();

  /**
   * Get the element that represents the specified index.
   * 
   * @param index the index of the row value
   * @return the the child element, or null if it does not exist
   */
  dart_html.Element getChildElement(int index) {
    dart_html.Element childContainer = getChildContainer();
    int childCount = childContainer.getChildCount();
    return (index < childCount) ? childContainer.children[index] : null;
  }

  /**
   * Get the element that has keyboard selection.
   * 
   * @return the keyboard selected element
   */
  dart_html.Element getKeyboardSelectedElement();

  /**
   * Check if keyboard navigation is being suppressed, such as when the user is
   * editing a cell.
   * 
   * @return true if suppressed, false if not
   */
  bool isKeyboardNavigationSuppressed();

  /**
   * Checks that the row is within bounds of the view.
   * 
   * @param row row index to check
   * @return true if within bounds, false if not
   */
  bool isRowWithinBounds(int row) {
    return row >= 0 && row < _presenter.getVisibleItemCount();
  }

  /**
   * Called when the widget is blurred.
   */
  void onBlur() {
  }

  /**
   * Called after {@link #onBrowserEvent(Event)} completes.
   * 
   * @param event the event that was fired
   */
  void onBrowserEvent2(Event event) {
  }

  /**
   * Called when the widget is focused.
   */
  void onFocus() {
  }

  /**
   * Called when the loading state changes. By default, this implementation
   * fires a {@link LoadingStateChangeEvent}.
   * 
   * @param state the new loading state
   */
  void onLoadingStateChanged(LoadingState state) {
    fireEvent(new LoadingStateChangeEvent(state));
  }

  
  void onUnload() {
    isFocused = false;
    super.onUnload();
  }

  /**
   * Render all row values into the specified {@link util.SafeHtmlBuilder}.
   * 
   * <p>
   * Subclasses can optionally throw an {@link UnsupportedOperationException} if
   * they prefer to render the rows in
   * {@link #replaceAllChildren(List, util.SafeHtml)} and
   * {@link #replaceChildren(List, int, util.SafeHtml)}. In this case, the
   * {@link util.SafeHtml} argument will be null. Though a bit hacky, this is
   * designed to supported legacy widgets that use {@link util.SafeHtmlBuilder}, and
   * newer widgets that use other builders, such as the ElementBuilder API.
   * </p>
   * 
   * @param sb the {@link util.SafeHtmlBuilder} to render into
   * @param values the row values
   * @param start the absolute start index of the values
   * @param selectionModel the {@link SelectionModel}
   * @throws UnsupportedOperationException if the values will be rendered in
   *           {@link #replaceAllChildren(List, util.SafeHtml)} and
   *           {@link #replaceChildren(List, int, util.SafeHtml)}
   */
  void renderRowValues(util.SafeHtmlBuilder sb, List<T> values, int start,
      SelectionModel<T> selectionModel); // throws UnsupportedOperationException;

  /**
   * Replace all children with the specified html.
   * 
   * @param values the values of the new children
   * @param html the html to render, or null if
   *          {@link #renderRowValues(util.SafeHtmlBuilder, List, int, SelectionModel)}
   *          throws an {@link UnsupportedOperationException}
   */
  void replaceAllChildren(List<T> values, util.SafeHtml html) {
    //AbstractHasData.replaceAllChildrenInWidget(this, getChildContainer(), html);
    AbstractHasData.replaceAllChildrenInWidgte(this, getChildContainer(), html);
  }

  /**
   * Convert the specified HTML into DOM elements and replace the existing
   * elements starting at the specified index. If the number of children
   * specified exceeds the existing number of children, the remaining children
   * should be appended.
   * 
   * @param values the values of the new children
   * @param start the start index to be replaced, relative to the page start
   * @param html the html to render, or null if
   *          {@link #renderRowValues(util.SafeHtmlBuilder, List, int, SelectionModel)}
   *          throws an {@link UnsupportedOperationException}
   */
  void replaceChildren(List<T> values, int start, util.SafeHtml html) {
    dart_html.Element newChildren = convertToElements(html);
    AbstractHasData.replaceChildrenInWidget(this, getChildContainer(), newChildren, start, html);
  }

  
  /**
   * Reset focus on the currently focused cell.
   * 
   * @return true if focus is taken, false if not
   */
  bool resetFocusOnCell();

  /**
   * Make an element focusable or not.
   * 
   * @param elem the element
   * @param focusable true to make focusable, false to make unfocusable
   */
  void setFocusable(dart_html.Element elem, bool focusable) {
    if (focusable) {
      ui.FocusImpl focusImpl = ui.FocusImpl.getFocusImplForWidget();
      dart_html.Element rowElem = elem;
      focusImpl.setTabIndex(rowElem, getTabIndex());
      if (_accessKey != 0) {
        focusImpl.setAccessKey(rowElem, _accessKey);
      }
    } else {
      // Chrome: Elements remain focusable after removing the tabIndex, so set
      // it to -1 first.
      elem.tabIndex = -1;
      elem.attributes.remove("tabIndex");
      elem.attributes.remove("accessKey");
    }
  }

  /**
   * Update an element to reflect its keyboard selected state.
   * 
   * @param index the index of the element
   * @param selected true if selected, false if not
   * @param stealFocus true if the row should steal focus, false if not
   */
  void setKeyboardSelected(int index, bool selected, bool stealFocus);

  /**
   * Update an element to reflect its selected state.
   * 
   * @param elem the element to update
   * @param selected true if selected, false if not
   * @deprecated this method is never called by AbstractHasData, render the
   *             selected styles in
   *             {@link #renderRowValues(util.SafeHtmlBuilder, List, int, SelectionModel)}
   */
//  @Deprecated
//  void setSelected(dart_html.Element elem, bool selected) {
//    // Never called.
//  }

  /**
   * Add a {@link ValueChangeHandler} that is called when the display values
   * change. Used by {@link CellBrowser} to detect when the displayed data
   * changes.
   * 
   * @param handler the handler
   * @return a {@link event.HandlerRegistration} to remove the handler
   */
  event.HandlerRegistration addValueChangeHandler(ValueChangeHandler<List<T>> handler) {
    return addHandler(handler, ValueChangeEvent.getType());
  }

  /**
   * Adopt the specified widget.
   * 
   * @param child the child to adopt
   */
  void adopt(ui.Widget child) {
    //child.@com.google.gwt.user.client.ui.ui.Widget::setParent(Lcom/google/gwt/user/client/ui/ui.Widget;)(this);
    child.setParent(this);
  }

  /**
   * Attach a child.
   * 
   * @param child the child to attach
   */
  void doAttach(ui.Widget child) {
    //child.@com.google.gwt.user.client.ui.ui.Widget::onAttach()();
    child.onAttach();
  }

  /**
   * Detach a child.
   * 
   * @param child the child to detach
   */
  void doDetach(ui.Widget child) {
    //child.@com.google.gwt.user.client.ui.ui.Widget::onDetach()();
    child.onDetach();
  }

  HasDataPresenter<T> getPresenter() {
    return _presenter;
  }

  /**
   * Show or hide an element.
   * 
   * @param element the element
   * @param show true to show, false to hide
   */
  void showOrHide(dart_html.Element element, bool show) {
    if (element == null) {
      return;
    }
    if (show) {
      element.style.display = "";
    } else {
      element.style.display = util.Display.NONE;
    }
  }
}


/**
 * Default implementation of a keyboard navigation handler.
 * 
 * @param <T> the data type of each row
 */
class DefaultKeyboardSelectionHandler<T> implements CellPreviewEventHandler<T> {

  /**
   * The number of rows to jump when PAGE_UP or PAGE_DOWN is pressed and the
   * {@link HasKeyboardPagingPolicy.KeyboardPagingPolicy} is
   * {@link HasKeyboardPagingPolicy.KeyboardPagingPolicy#INCREASE_RANGE}.
   */
  static const int _PAGE_INCREMENT = 30;

  final AbstractHasData<T> _display;

  /**
   * Construct a new keyboard selection handler for the specified view.
   * 
   * @param _display the _display being handled
   */
  DefaultKeyboardSelectionHandler(this._display);

  AbstractHasData<T> getDisplay() {
    return _display;
  }

  
  void onCellPreview(CellPreviewEvent<T> evt) {
    dart_html.Event nativeEvent = evt.getNativeEvent();
    String eventType = nativeEvent.type;
    if (event.BrowserEvents.KEYDOWN == eventType && !evt.isCellEditing()) {
      /*
       * Handle keyboard navigation, unless the cell is being edited. If the
       * cell is being edited, we do not want to change rows.
       * 
       * Prevent default on navigation events to prevent default scrollbar
       * behavior.
       */
      switch (nativeEvent.getKeyCode()) {
        case KeyCodes.KEY_DOWN:
          nextRow();
          handledEvent(evt);
          return;
        case KeyCodes.KEY_UP:
          prevRow();
          handledEvent(evt);
          return;
        case KeyCodes.KEY_PAGEDOWN:
          nextPage();
          handledEvent(evt);
          return;
        case KeyCodes.KEY_PAGEUP:
          prevPage();
          handledEvent(evt);
          return;
        case KeyCodes.KEY_HOME:
          home();
          handledEvent(evt);
          return;
        case KeyCodes.KEY_END:
          end();
          handledEvent(evt);
          return;
        case 32:
          // Prevent the list box from scrolling.
          handledEvent(evt);
          return;
      }
    } else if (event.BrowserEvents.CLICK == eventType) {
      /*
       * Move keyboard focus to the clicked row, even if the Cell is being
       * edited. Unlike key events, we aren't moving the currently selected
       * row, just updating it based on where the user clicked.
       */
      int relRow = evt.getIndex() - _display.getPageStart();

      // If a natively focusable element was just clicked, then do not steal
      // focus.
      bool isFocusable = false;
      dart_html.Element target = nativeEvent.target as dart_html.Element;
      isFocusable = CellBasedWidgetImpl.get().isFocusable(target);
      _display.setKeyboardSelectedRow(relRow, !isFocusable);

      // Do not cancel the event as the click may have occurred on a Cell.
    } else if (event.BrowserEvents.FOCUS == eventType) {
      // Move keyboard focus to match the currently focused element.
      int relRow = evt.getIndex() - _display.getPageStart();
      if (_display.getKeyboardSelectedRow() != relRow) {
        // Do not steal focus as this was a focus event.
        _display.setKeyboardSelectedRow(evt.getIndex(), false);

        // Do not cancel the event as the click may have occurred on a Cell.
        return;
      }
    }
  }

  // Visible for testing.
  void end() {
    setKeyboardSelectedRow(_display.getRowCount() - 1);
  }

  void handledEvent(CellPreviewEvent<T> evt) {
    evt.setCanceled(true);
    evt.getNativeEvent().preventDefault();
  }

  // Visible for testing.
  void home() {
    setKeyboardSelectedRow(-_display.getPageStart());
  }

  // Visible for testing.
  void nextPage() {
    KeyboardPagingPolicy keyboardPagingPolicy = _display.getKeyboardPagingPolicy();
    if (KeyboardPagingPolicy.CHANGE_PAGE == keyboardPagingPolicy) {
      // 0th index of next page.
      setKeyboardSelectedRow(_display.getPageSize());
    } else if (KeyboardPagingPolicy.INCREASE_RANGE == keyboardPagingPolicy) {
      setKeyboardSelectedRow(_display.getKeyboardSelectedRow() + _PAGE_INCREMENT);
    }
  }

  // Visible for testing.
  void nextRow() {
    setKeyboardSelectedRow(_display.getKeyboardSelectedRow() + 1);
  }

  // Visible for testing.
  void prevPage() {
    KeyboardPagingPolicy keyboardPagingPolicy = _display.getKeyboardPagingPolicy();
    if (KeyboardPagingPolicy.CHANGE_PAGE == keyboardPagingPolicy) {
      // 0th index of previous page.
      setKeyboardSelectedRow(-_display.getPageSize());
    } else if (KeyboardPagingPolicy.INCREASE_RANGE == keyboardPagingPolicy) {
      setKeyboardSelectedRow(_display.getKeyboardSelectedRow() - _PAGE_INCREMENT);
    }
  }
  
// Visible for testing.
  void prevRow() {
    setKeyboardSelectedRow(_display.getKeyboardSelectedRow() - 1);
  }

  // Visible for testing.
  void setKeyboardSelectedRow(int row) {
    _display.setKeyboardSelectedRow(row, true);
  }
}

/**
 * Implementation of {@link HasDataPresenter.View} used by this widget.
 * 
 * @param <T> the data type of the view
 */
class View<T> implements HasDataPresenterView<T> {

  final AbstractHasData<T> _hasData;
  bool _wasFocused;

  View(this._hasData);
  
  event.HandlerRegistration addHandler(handler, event.EventType type) {
    return _hasData.addHandler(handler, type);
  }

  
  void replaceAllChildren(List<T> values, SelectionModel<T> selectionModel,
      bool stealFocus) {
    util.SafeHtml html = _renderRowValues(values, _hasData.getPageStart(), selectionModel);

    // Removing elements can fire a blur event, which we ignore.
    _hasData.isFocused = _hasData.isFocused || stealFocus;
    _wasFocused = _hasData.isFocused;
    _hasData.isRefreshing = true;
    _hasData.replaceAllChildren(values, html);
    _hasData.isRefreshing = false;

    // Ensure that the keyboard selected element is focusable.
    dart_html.Element elem = _hasData.getKeyboardSelectedElement();
    if (elem != null) {
      _hasData.setFocusable(elem, true);
      if (_hasData.isFocused) {
        _hasData.onFocus();
      }
    }

    _fireValueChangeEvent();
  }

  
  void replaceChildren(List<T> values, int start,
                       SelectionModel<T> selectionModel, bool stealFocus) {
    util.SafeHtml html = renderRowValues(values, _hasData.getPageStart() + start, selectionModel);

    // Removing elements can fire a blur event, which we ignore.
    _hasData.isFocused = _hasData.isFocused || stealFocus;
    _wasFocused = _hasData.isFocused;
    _hasData.isRefreshing = true;
    _hasData.replaceChildren(values, start, html);
    _hasData.isRefreshing = false;

    // Ensure that the keyboard selected element is focusable.
    dart_html.Element elem = _hasData.getKeyboardSelectedElement();
    if (elem != null) {
      _hasData.setFocusable(elem, true);
      if (_hasData.isFocused) {
        _hasData.onFocus();
      }
    }

    _fireValueChangeEvent();
  }


  void resetFocus() {
    if (_wasFocused) {
      CellBasedWidgetImpl.get().resetFocus(new ViewScheduledCommand(this));
    }
  }

  
  void setKeyboardSelected(int index, bool seleted, bool stealFocus) {
    _hasData.isFocused = _hasData.isFocused || stealFocus;
    _hasData.setKeyboardSelected(index, seleted, stealFocus);
  }

  
  void setLoadingState(LoadingState state) {
    _hasData.isRefreshing = true;
    _hasData.onLoadingStateChanged(state);
    _hasData.isRefreshing = false;
  }

  /**
   * Fire a value change event.
   */
  void _fireValueChangeEvent() {
    // Use an anonymous class to override ValueChangeEvents's protected
    // constructor. We can't call ValueChangeEvent.fire() because this class
    // doesn't implement HasValueChangeHandlers.
    _hasData.fireEvent(new event.ValueChangeEvent<List<T>>(_hasData.getVisibleItems()));
  }

  /**
   * Render a list of row values.
   * 
   * @param values the row values
   * @param start the absolute start index of the values
   * @param selectionModel the {@link SelectionModel}
   * @return null, unless the implementation renders using util.SafeHtml
   */
  util.SafeHtml _renderRowValues(List<T> values, int start,
                                   SelectionModel<T> selectionModel) {
    try {
      util.SafeHtmlBuilder sb = new util.SafeHtmlBuilder();
      _hasData.renderRowValues(sb, values, start, selectionModel);
      return sb.toSafeHtml();
    } on Exception catch (e) {
      // If _renderRowValues throws, the implementation will render directly in
      // the replaceChildren method.
      return null;
    }
  }
}

class _Widget extends ui.Widget {
  
  _Widget.fromElement(dart_html.Element elem)  {
    setElement(elem);
  }
}

class ViewScheduledCommand extends scheduler.ScheduledCommand {
  
  View _view;
  
  ViewScheduledCommand(this._view);
  
  void execute() {
    if (!_view._hasData.resetFocusOnCell()) {
      dart_html.Element elem = _view_hasData.getKeyboardSelectedElement();
      if (elem != null) {
        elem.focus();
      }
    }
  }
}