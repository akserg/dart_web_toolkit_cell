//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_view;

/**
 * A single column list of cells.
 * 
 * <p>
 * <h3>Examples</h3>
 * <dl>
 * <dt>Trivial example</dt>
 * <dd>{@example com.google.gwt.examples.cellview.CellListExample}</dd>
 * <dt>Handling user input with ValueUpdater</dt>
 * <dd>{@example com.google.gwt.examples.cellview.CellListValueUpdaterExample}</dd>
 * <dt>Pushing data with List Data Provider (backed by {@link List})</dt>
 * <dd>{@example com.google.gwt.examples.view.ListDataProviderExample}</dd>
 * <dt>Pushing data asynchronously with Async Data Provider</dt>
 * <dd>{@example com.google.gwt.examples.view.AsyncDataProviderExample}</dd>
 * <dt>Writing a custom data provider</dt>
 * <dd>{@example com.google.gwt.examples.view.RangeChangeHandlerExample}</dd>
 * <dt>Using a key provider to track objects as they change</dt>
 * <dd>{@example com.google.gwt.examples.view.KeyProviderExample}</dd>
 * </dl>
 * </p>
 * 
 * @param <T> the data type of list items
 */
class CellList<T> extends AbstractHasData<T> {
  /**
   * The default page size.
   */
  static const int _DEFAULT_PAGE_SIZE = 25;

  static CellListResources _DEFAULT_RESOURCES;

  static Template TEMPLATE; // = GWT.create(Template.class);

  static CellListResources _getDefaultResources() {
    if (_DEFAULT_RESOURCES == null) {
      _DEFAULT_RESOURCES = new _CellListResourcesImpl();
    }
    return _DEFAULT_RESOURCES;
  }

  final Cell<T> cell;
  bool _cellIsEditing = false;
  dart_html.Element _childContainer;
  util.SafeHtml _emptyListMessage = util.SafeHtmlUtils.fromTrustedString("");
  final ui.SimplePanel _emptyListWidgetContainer = new ui.SimplePanel();
  final ui.SimplePanel _loadingIndicatorContainer = new ui.SimplePanel();

  /**
   * A {@link ui.DeckPanel} to hold widgets associated with various loading states.
   */
  final ui.DeckPanel _messagesPanel = new ui.DeckPanel();

  //ui.Style _style;
  CellListStyle _style;

  ValueUpdater<T> _valueUpdater;

  /**
   * Construct a new {@link CellList} with the specified {@link CellListResources} and
   * {@link ProvidesKey key provider}.
   * 
   * @param cell the cell used to render each item
   * @param resources the resources used for this widget
   * @param keyProvider an instance of ProvidesKey<T>, or null if the record
   *          object should act as its own key
   */
  CellList(this.cell, {CellListResources resources:null, ProvidesKey<T> keyProvider:null}) : super.fromElement(new dart_html.DivElement(), _DEFAULT_PAGE_SIZE, keyProvider) {
    if (resources == null) {
      resources = _getDefaultResources();
    }
    this._style = resources.cellListStyle();
//    this._style.ensureInjected();

    String widgetStyle = this._style.cellListWidget();
    if (widgetStyle != null) {
      // The widget _style is null when used in CellBrowser.
      addStyleName(widgetStyle);
    }

    // Add the child container.
    _childContainer = new dart_html.DivElement();
    _childContainer.id = "_childContainer";
    dart_html.DivElement outerDiv = getElement();
    outerDiv.id = "outerDiv";
    outerDiv.append(_childContainer);

    // Attach the message panel.
    outerDiv.append(_messagesPanel.getElement());
    _messagesPanel.getElement().id = "_messagesPanel";
    adopt(_messagesPanel);
    _messagesPanel.add(_emptyListWidgetContainer);
    _emptyListWidgetContainer.getElement().id = "_emptyListWidgetContainer";
    _messagesPanel.add(_loadingIndicatorContainer);
    _loadingIndicatorContainer.getElement().id = "_loadingIndicatorContainer";
    

    // Sink events that the cell consumes.
    CellBasedWidgetImpl.get().sinkEvents(this, cell.getConsumedEvents());
  }

  /**
   * Get the message that is displayed when there is no data.
   * 
   * @return the empty message
   * @see #setEmptyListMessage(util.SafeHtml)
   * @deprecated as of GWT 2.3, use {@link #getEmptyListWidget()} instead
   */
//  @Deprecated
//  util.SafeHtml getEmptyListMessage() {
//    return _emptyListMessage;
//  }

  /**
   * Get the widget displayed when the list has no rows.
   * 
   * @return the empty list widget
   */
  ui.Widget getEmptyListWidget() {
    return _emptyListWidgetContainer.getWidget();
  }

  /**
   * Get the widget displayed when the data is loading.
   * 
   * @return the loading indicator
   */
  ui.Widget getLoadingIndicator() {
    return _loadingIndicatorContainer.getWidget();
  }

  /**
   * Get the {@link dart_html.Element} for the specified index. If the element has not
   * been created, null is returned.
   * 
   * @param indexOnPage the index on the page
   * @return the element, or null if it doesn't exists
   * @throws IndexOutOfBoundsException if the index is outside of the current
   *           page
   */
  dart_html.Element getRowElement(int indexOnPage) {
    getPresenter().flush();
    checkRowBounds(indexOnPage);
    if (_childContainer.children.length > indexOnPage) {
      return _childContainer.children[indexOnPage];
    }
    return null;
  }

  /**
   * Set the message to display when there is no data.
   * 
   * @param html the message to display when there are no results
   * @see #getEmptyListMessage()
   * @deprecated as of GWT 2.3, use
   *             {@link #setEmptyListWidget(com.google.gwt.user.client.ui.ui.Widget)}
   *             instead
   */
//  @Deprecated
//  void setEmptyListMessage(util.SafeHtml html) {
//    this._emptyListMessage = html;
//    setEmptyListWidget(html == null ? null : new HTML(html));
//  }

  /**
   * Set the widget to display when the list has no rows.
   * 
   * @param widget the empty data widget
   */
  void setEmptyListWidget(ui.Widget widget) {
    _emptyListWidgetContainer.setWidget(widget);
  }

  /**
   * Set the widget to display when the data is loading.
   * 
   * @param widget the loading indicator
   */
  void setLoadingIndicator(ui.Widget widget) {
    _loadingIndicatorContainer.setWidget(widget);
  }

  /**
   * Set the value updater to use when cells modify items.
   * 
   * @param valueUpdater the {@link ValueUpdater}
   */
  void setValueUpdater(ValueUpdater<T> valueUpdater) {
    this._valueUpdater = valueUpdater;
  }

  bool dependsOnSelection() {
    return cell.dependsOnSelection();
  }

  
  void doAttachChildren() {
    try {
      doAttach(_messagesPanel);
    } on Exception catch (e) {
      throw new ui.AttachDetachException(new Set.from([e]));
    }
  }

  
  void doDetachChildren() {
    try {
      doDetach(_messagesPanel);
    } on Exception catch (e) {
      throw new ui.AttachDetachException(new Set.from([e]));
    }
  }

  /**
   * Fire an event to the cell.
   * 
   * @param context the {@link Context} of the cell
   * @param event the event that was fired
   * @param parent the parent of the cell
   * @param value the value of the cell
   */
  void fireEventToCell(Context context, dart_html.Event event, dart_html.Element parent, T value) {
    Set<String> consumedEvents = cell.getConsumedEvents();
    if (consumedEvents != null && consumedEvents.contains(event.type)) {
      bool cellWasEditing = cell.isEditing(context, parent, value);
      cell.onBrowserEvent(context, parent, value, event, _valueUpdater);
      _cellIsEditing = cell.isEditing(context, parent, value);
      if (cellWasEditing && !_cellIsEditing) {
        CellBasedWidgetImpl.get().resetFocus(new scheduler.ScheduledCommandAdapter(setFocus(true)));
      }
    }
  }

  /**
   * Return the cell used to render each item.
   */
  Cell<T> getCell() {
    return cell;
  }

  /**
   * Get the parent element that wraps the cell from the list item. Override
   * this method if you add structure to the element.
   * 
   * @param item the row element that wraps the list item
   * @return the parent element of the cell
   */
  dart_html.Element getCellParent(dart_html.Element item) {
    return item;
  }

  
  dart_html.Element getChildContainer() {
    return _childContainer;
  }

  
  dart_html.Element getKeyboardSelectedElement() {
    // Do not use getRowElement() because that will flush the presenter.
    int rowIndex = getKeyboardSelectedRow();
    if (rowIndex >= 0 && _childContainer.children.length > rowIndex) {
      return _childContainer.children[rowIndex];
    }
    return null;
  }

  
  bool isKeyboardNavigationSuppressed() {
    return _cellIsEditing;
  }

  
  void onBlur() {
    // Remove the keyboard selection style.
    dart_html.Element elem = getKeyboardSelectedElement();
    if (elem != null) {
      String className = elem.$dom_className;
      int i = className.replaceFirst(_style.cellListKeyboardSelectedItem(), '');
    }
  }

  void onBrowserEvent2(dart_html.Event evt) {
    // Get the event target.
    dart_html.EventTarget eventTarget = evt.target;
    if (!(eventTarget is dart_html.Element)) {
      return;
    }
    dart_html.Element target = eventTarget;

    // Forward the event to the cell.
    String idxString = "";
    dart_html.Element cellTarget = target;
    while ((cellTarget != null) && ((idxString = cellTarget.attribute["__idx"]).length == 0)) {
      cellTarget = cellTarget.parent;
    }
    if (idxString.length > 0) {
      // Select the item if the cell does not consume events. Selection occurs
      // before firing the event to the cell in case the cell operates on the
      // currently selected item.
      String eventType = evt.type;
      bool isClick = event.BrowserEvents.CLICK == eventType;
      int idx = int.parse(idxString);
      int indexOnPage = idx - getPageStart();
      if (!isRowWithinBounds(indexOnPage)) {
        // If the event causes us to page, then the index will be out of bounds.
        return;
      }

      // Get the cell parent before doing selection in case the list is redrawn.
      bool isSelectionHandled =
          cell.handlesSelection()
              || KeyboardSelectionPolicy.BOUND_TO_SELECTION == getKeyboardSelectionPolicy();
      dart_html.Element cellParent = getCellParent(cellTarget);
      T value = getVisibleItem(indexOnPage);
      Context context = new Context(idx, 0, getValueKey(value));
      CellPreviewEvent<T> previewEvent =
          CellPreviewEvent.fire(this, evt, this, context, value, _cellIsEditing,
              isSelectionHandled);

      // Fire the event to the cell if the list has not been refreshed.
      if (!previewEvent.isCanceled()) {
        fireEventToCell(context, evt, cellParent, value);
      }
    }
  }

  
  void onFocus() {
    // Add the keyboard selection style.
    dart_html.Element elem = getKeyboardSelectedElement();
    if (elem != null) {
      elem.addClassName(_style.cellListKeyboardSelectedItem());
    }
  }

  /**
   * Called when the loading state changes.
   * 
   * @param state the new loading state
   */
  
  void onLoadingStateChanged(LoadingState state) {
    ui.Widget message = null;
    if (state == LoadingState.LOADING) {
      // Loading indicator.
      message = _loadingIndicatorContainer;
    } else if (state == LoadingState.LOADED && getPresenter().isEmpty()) {
      // Empty table.
      message = _emptyListWidgetContainer;
    }

    // Switch out the message to display.
    if (message != null) {
      _messagesPanel.showWidget(_messagesPanel.getWidgetIndex(message));
    }

    // Show the correct container.
    showOrHide(getChildContainer(), message == null);
    _messagesPanel.setVisible(message != null);

    // Fire an event.
    super.onLoadingStateChanged(state);
  }

  
  void renderRowValues(util.SafeHtmlBuilder sb, List<T> values, int start,
      SelectionModel<T> selectionModel) {
    String keyboardSelectedItem = " " + _style.cellListKeyboardSelectedItem();
    String selectedItem = " " + _style.cellListSelectedItem();
    String evenItem = _style.cellListEvenItem();
    String oddItem = _style.cellListOddItem();
    int keyboardSelectedRow = getKeyboardSelectedRow() + getPageStart();
    int length = values.size();
    int end = start + length;
    for (int i = start; i < end; i++) {
      T value = values.get(i - start);
      bool isSelected = selectionModel == null ? false : selectionModel.isSelected(value);

      StringBuilder classesBuilder = new StringBuilder();
      classesBuilder.append(i % 2 == 0 ? evenItem : oddItem);
      if (isSelected) {
        classesBuilder.append(selectedItem);
      }

      util.SafeHtmlBuilder cellBuilder = new util.SafeHtmlBuilder();
      Context context = new Context(i, 0, getValueKey(value));
      cell.render(context, value, cellBuilder);
      sb.append(TEMPLATE.div(i, classesBuilder.toString(), cellBuilder.toSafeHtml()));
    }
  }

  
  bool resetFocusOnCell() {
    int row = getKeyboardSelectedRow();
    if (isRowWithinBounds(row)) {
      dart_html.Element rowElem = getKeyboardSelectedElement();
      dart_html.Element cellParent = getCellParent(rowElem);
      T value = getVisibleItem(row);
      Context context = new Context(row + getPageStart(), 0, getValueKey(value));
      return cell.resetFocus(context, cellParent, value);
    }
    return false;
  }

  
  void setKeyboardSelected(int index, bool selected, bool stealFocus) {
    if (!isRowWithinBounds(index)) {
      return;
    }

    dart_html.Element elem = getRowElement(index);
    if (!selected || isFocused || stealFocus) {
      setStyleName(elem, _style.cellListKeyboardSelectedItem(), selected);
    }
    setFocusable(elem, selected);
    if (selected && stealFocus && !_cellIsEditing) {
      elem.focus();
      onFocus();
    }
  }

  /**
   * @deprecated this method is never called by AbstractHasData, render the
   *             selected styles in
   *             {@link #renderRowValues(util.SafeHtmlBuilder, List, int, SelectionModel)}
   */
//  
//  @Deprecated
//  void setSelected(dart_html.Element elem, bool selected) {
//    setStyleName(elem, _style.cellListSelectedItem(), selected);
//  }
}

/**
 * A ClientBundle that provides images for this widget.
 */
abstract class CellListResources extends resource.ClientBundle {
  /**
   * The background used for selected items.
   */
  //@ImageOptions(repeatStyle = RepeatStyle.Horizontal, flipRtl = true)
  resource.ImageResource cellListSelectedBackground();

  /**
   * The styles used in this widget.
   */
  //@Source(Style.DEFAULT_CSS)
  //util.Style cellListStyle();
  CellListStyle cellListStyle();
}

class _CellListResourcesImpl implements CellListResources {
  
  CellListStyle _style;
  resource.ImageResource _backgroundImage;
  
  /**
   * The background used for selected items.
   */
  resource.ImageResource cellListSelectedBackground() {
    if (_backgroundImage == null) {
      _backgroundImage = _getTreeImageResourcePrototype("cellListSelectedBackground.png");
    }
    return _backgroundImage;
  }
  
  /**
   * The styles used in this widget.
   */
  //util.Style cellListStyle() {
  CellListStyle cellListStyle() {
    if (_style == null) {
      _style = new CellListStyle();
    }
    return _style;
  }
  
  resource.ImageResourcePrototype _getTreeImageResourcePrototype(String name) {
    //String uri = core.DWT.getModuleBaseURL() + "resource/images/cell/" + name;
    String uri = "src/packages/" + "resource/images/cell/" + name;
    resource.ImageResourcePrototype imageResource = new resource.ImageResourcePrototype(name, 
        util.UriUtils.fromTrustedString(uri), 0, 0, 82, 26, false, false);
    return imageResource;
  }
}

/**
 * Styles used by this widget.
 */
//@ImportedWithPrefix("gwt-CellList")
class CellListStyle{ // extends resource.CssResource {
  /**
   * The path to the default CSS styles used by this resource.
   */
  String DEFAULT_CSS = "com/google/gwt/user/cellview/client/CellList.css";

  /**
   * Applied to even items.
   */
  String cellListEvenItem() {
    return "cursor: pointer; zoom: 1;";
  }

  /**
   * Applied to the keyboard selected item.
   */
  String cellListKeyboardSelectedItem() {
    return "background: #ffc;";
  }

  /**
   * Applied to odd items.
   */
  String cellListOddItem() {
    return "cursor: pointer; zoom: 1;";
  }

  /**
   * Applied to selected items.
   */
  String cellListSelectedItem() {
    return '''
gwt-image: "cellListSelectedBackground";
background-color: #628cd5;
color: white;
height: auto;
overflow: visible;
''';
  }

  /**
   * Applied to the widget.
   */
  String cellListWidget() {
    return "gwt-CellList";
  }
}

abstract class Template extends util.SafeHtmlTemplates {
  //@Template("<div onclick=\"\" __idx=\"{0}\" class=\"{1}\" style=\"outline:none;\" >{2}</div>")
  util.SafeHtml div(int idx, String classes, util.SafeHtml cellContents);
}

class CellListScheduledCommand extends scheduler.ScheduledCommand {
  
  void execute() {
    setFocus(true);
  }
}