//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * <p>
 * Presenter implementation of {@link HasData} that presents data for various
 * cell based widgets. This class contains most of the shared logic used by
 * these widgets, making it easier to test the common code.
 * <p>
 * <p>
 * In proper MVP design, user code would interact with the presenter. However,
 * that would complicate the widget code. Instead, each widget owns its own
 * presenter and contains its own View. The widget forwards commands through to
 * the presenter, which then updates the widget via the view. This keeps the
 * user facing API simpler.
 * <p>
 * <p>
 * Updates are not pushed to the view immediately. Instead, the presenter
 * collects updates and resolves them all in a finally command. This reduces the
 * total number of DOM manipulations, and makes it easier to handle side effects
 * in user code triggered by the rendering pass. The view is responsible for
 * called {@link #flush()} to force the presenter to synchronize the view when
 * needed.
 * </p>
 * 
 * @param <T> the data type of items in the list
 */
class HasDataPresenter<T> implements HasData<T>, HasKeyProvider<T>, HasKeyboardPagingPolicy {

  /**
   * The number of rows to jump when PAGE_UP or PAGE_DOWN is pressed and the
   * {@link HasKeyboardPagingPolicy.KeyboardPagingPolicy} is
   * {@link HasKeyboardPagingPolicy.KeyboardPagingPolicy#INCREASE_RANGE}.
   */
  static final int PAGE_INCREMENT = 30;

  /**
   * The maximum number of times we can try to
   * {@link #resolvePendingState(List<int>)} before we assume there is an
   * infinite loop.
   */
  static final int _LOOP_MAXIMUM = 10;

  /**
   * The minimum number of rows that need to be replaced before we do a redraw.
   */
  static final int _REDRAW_MINIMUM = 5;

  /**
   * The threshold of new data after which we redraw the entire view instead of
   * replacing specific rows.
   * 
   * TODO(jlabanca): Find the optimal value for the threshold.
   */
  static final double _REDRAW_THRESHOLD = 0.30;

  /**
   * Sort a native integer array numerically.
   * 
   * @param array the array to sort
   */
  static void sortJsArrayInteger(List<int> array) {
    // sort() sorts lexicographically by default.
    array.sort((x, y) {
      return x - y;
    });
  }

  final HasData<T> _display;

  /**
   * A bool indicating that we are in the process of resolving state.
   */
  bool _isResolvingState = false;

  KeyboardPagingPolicy _keyboardPagingPolicy = KeyboardPagingPolicy.CHANGE_PAGE;
  KeyboardSelectionPolicy _keyboardSelectionPolicy = KeyboardSelectionPolicy.ENABLED;

  final data.ProvidesKey<T> _keyProvider;

  /**
   * The pending state of the presenter to be pushed to the view.
   */
  HasDataPresenterPendingState<T> _pendingState;

  /**
   * The command used to resolve the pending state.
   */
  scheduler.ScheduledCommand _pendingStateCommand;

  /**
   * A counter used to detect infinite loops in
   * {@link #resolvePendingState(List<int>)}. An infinite loop can occur if
   * user code, such as reading the {@link SelectionModel}, causes the table to
   * have a pending state.
   */
  int _pendingStateLoop = 0;

  event.HandlerRegistration _selectionHandler;
  SelectionModel<T> _selectionModel;

  /**
   * The current state of the presenter reflected in the view. We intentionally
   * use the interface, which only has getters, to ensure that we do not
   * accidently modify the current state.
   */
  HasDataPresenterState<T> _state;

  final HasDataPresenterView<T> _view;

  /**
   * Construct a new {@link HasDataPresenter}.
   * 
   * @param _display the _display that is being presented
   * @param _view the view implementation
   * @param pageSize the default page size
   */
  HasDataPresenter(this._display, this._view, int pageSize, this._keyProvider) {
    this._state = new _HasDataPresenterDefaultState<T>(pageSize);
  }

  event.HandlerRegistration addCellPreviewHandler(CellPreviewEventHandler<T> handler) {
    return _view.addHandler(handler, CellPreviewEvent.TYPE);
  }

  event.HandlerRegistration addLoadingStateChangeHandler(LoadingStateChangeEventHandler handler) {
    return _view.addHandler(handler, LoadingStateChangeEvent.TYPE);
  }

  event.HandlerRegistration addRangeChangeHandler(RangeChangeEventHandler handler) {
    return _view.addHandler(handler, RangeChangeEvent.TYPE);
  }

  event.HandlerRegistration addRowCountChangeHandler(RowCountChangeEventHandler handler) {
    return _view.addHandler(handler, RowCountChangeEvent.TYPE);
  }

  /**
   * Clear the row value associated with the keyboard selected row.
   */
  void clearKeyboardSelectedRowValue() {
    if (getKeyboardSelectedRowValue() != null) {
      _ensurePendingState().keyboardSelectedRowValue = null;
    }
  }

  /**
   * Clear the {@link SelectionModel} without updating the view.
   */
  void clearSelectionModel() {
    if (_selectionHandler != null) {
      _selectionHandler.removeHandler();
      _selectionHandler = null;
    }
    _selectionModel = null;
  }

  /**
   * @throws UnsupportedOperationException
   */
  void fireEvent(event.DwtEvent evt) {
    // HasData should fire their own events.
    throw new Exception("UnsupportedOperationException");
  }

  /**
   * Flush pending changes to the view.
   */
  void flush() {
    _resolvePendingState(null);
  }

  /**
   * Get the current page size. This is usually the page size, but can be less
   * if the data size cannot fill the current page.
   * 
   * @return the size of the current page
   */
  int getCurrentPageSize() {
    return math.min(_getPageSize(), getRowCount() - _getPageStart());
  }

  KeyboardPagingPolicy getKeyboardPagingPolicy() {
    return _keyboardPagingPolicy;
  }

  /**
   * Get the index of the keyboard selected row relative to the page start.
   * 
   * @return the row index, or -1 if disabled
   */
  int getKeyboardSelectedRow() {
    return KeyboardSelectionPolicy.DISABLED == _keyboardSelectionPolicy ? -1 : 
      _getCurrentState().getKeyboardSelectedRow();
  }

  /**
   * Get the index of the keyboard selected row relative to the page start as it
   * appears in the view, regardless of whether or not there is a pending
   * change.
   * 
   * @return the row index, or -1 if disabled
   */
  int getKeyboardSelectedRowInView() {
    return KeyboardSelectionPolicy.DISABLED == _keyboardSelectionPolicy ? -1 : 
      _state.getKeyboardSelectedRow();
  }

  /**
   * Get the value that the user selected.
   * 
   * @return the value, or null if a value was not selected
   */
  T getKeyboardSelectedRowValue() {
    return KeyboardSelectionPolicy.DISABLED == _keyboardSelectionPolicy ? null : 
      _getCurrentState().getKeyboardSelectedRowValue();
  }

  
  KeyboardSelectionPolicy getKeyboardSelectionPolicy() {
    return _keyboardSelectionPolicy;
  }

  
  data.ProvidesKey<T> getKeyProvider() {
    return _keyProvider;
  }

  /**
   * Get the overall data size.
   * 
   * @return the data size
   */
  
  int getRowCount() {
    return _getCurrentState().getRowCount();
  }

  
  SelectionModel<T> getSelectionModel() {
    return _selectionModel;
  }

  
  T getVisibleItem(int indexOnPage) {
    return _getCurrentState().getRowDataValue(indexOnPage);
  }

  
  int getVisibleItemCount() {
    return _getCurrentState().getRowDataSize();
  }

  
  List<T> getVisibleItems() {
    return _getCurrentState().getRowDataValues();
  }

  /**
   * Return the range of data being displayed.
   */
  
  Range getVisibleRange() {
    return new Range(_getPageStart(), _getPageSize());
  }

  /**
   * Check whether or not there is a pending state. If there is a pending state,
   * views might skip DOM updates and wait for the new data to be rendered when
   * the pending state is resolved.
   * 
   * @return true if there is a pending state, false if not
   */
  bool hasPendingState() {
    return _pendingState != null;
  }

  /**
   * Check whether or not the data set is empty. That is, the row count is
   * exactly 0.
   * 
   * @return true if data set is empty
   */
  bool isEmpty() {
    return isRowCountExact() && getRowCount() == 0;
  }

  
  bool isRowCountExact() {
    return _getCurrentState().isRowCountExact();
  }

  /**
   * Redraw the list with the current data.
   */
  void redraw() {
    _ensurePendingState()._redrawRequired = true;
  }

  
  void setKeyboardPagingPolicy(KeyboardPagingPolicy policy) {
    if (policy == null) {
      throw new Exception("KeyboardPagingPolicy cannot be null");
    }
    this._keyboardPagingPolicy = policy;
  }

  /**
   * Set the row index of the keyboard selected element.
   * 
   * @param index the row index
   * @param stealFocus true to steal focus
   * @param forceUpdate force the update even if the row didn't change
   */
  void setKeyboardSelectedRow(int index, bool stealFocus, bool forceUpdate) {
    // Early exit if disabled.
    if (KeyboardSelectionPolicy.DISABLED == _keyboardSelectionPolicy) {
      return;
    }

    // Clip the row index if the paging policy is limited.
    if (_keyboardPagingPolicy.isLimitedToRange()) {
      // index will be 0 if visible item count is 0.
      index = math.max(0, math.min(index, getVisibleItemCount() - 1));
    }

    // The user touched the view.
    _ensurePendingState().viewTouched = true;

    /*
     * Early exit if the keyboard selected row has not changed and the keyboard
     * selected value is already set.
     */
    if (!forceUpdate && getKeyboardSelectedRow() == index && getKeyboardSelectedRowValue() != null) {
      return;
    }

    // Trim to within bounds.
    int pageStart = _getPageStart();
    int pageSize = _getPageSize();
    int rowCount = getRowCount();
    int absIndex = pageStart + index;
    if (absIndex >= rowCount && isRowCountExact()) {
      absIndex = rowCount - 1;
    }
    index = math.max(0, absIndex) - pageStart;
    if (_keyboardPagingPolicy.isLimitedToRange()) {
      index = math.max(0, math.min(index, pageSize - 1));
    }

    // Select the new index.
    int newPageStart = pageStart;
    int newPageSize = pageSize;
    HasDataPresenterPendingState<T> pending = _ensurePendingState();
    pending.keyboardSelectedRow = 0;
    pending.keyboardSelectedRowValue = null;
    pending._keyboardSelectedRowChanged = true;
    if (index >= 0 && index < pageSize) {
      pending.keyboardSelectedRow = index;
      pending.keyboardSelectedRowValue =
          index < pending.getRowDataSize() ? _ensurePendingState().getRowDataValue(index) : null;
      pending._keyboardStealFocus = stealFocus;
      return;
    } else if (KeyboardPagingPolicy.CHANGE_PAGE == _keyboardPagingPolicy) {
      // Go to previous page.
      while (index < 0) {
        int shift = math.min(pageSize, newPageStart);
        newPageStart -= shift;
        index += shift;
      }

      // Go to next page.
      while (index >= pageSize) {
        newPageStart += pageSize;
        index -= pageSize;
      }
    } else if (KeyboardPagingPolicy.INCREASE_RANGE == _keyboardPagingPolicy) {
      // Increase range at the beginning.
      while (index < 0) {
        int shift = math.min(PAGE_INCREMENT, newPageStart);
        newPageSize += shift;
        newPageStart -= shift;
        index += shift;
      }

      // Increase range at the end.
      while (index >= newPageSize) {
        newPageSize += PAGE_INCREMENT;
      }
      if (isRowCountExact()) {
        newPageSize = math.min(newPageSize, rowCount - newPageStart);
        if (index >= rowCount) {
          index = rowCount - 1;
        }
      }
    }

    // Update the range if it changed.
    if (newPageStart != pageStart || newPageSize != pageSize) {
      pending.keyboardSelectedRow = index;
      _setVisibleRange(new Range(newPageStart, newPageSize), false, false);
    }
  }

  
  void setKeyboardSelectionPolicy(KeyboardSelectionPolicy policy) {
    if (policy == null) {
      throw new Exception("KeyboardSelectionPolicy cannot be null");
    }
    this._keyboardSelectionPolicy = policy;
  }

  /**
   * @throws UnsupportedOperationException
   */
//  void setRowCount(int count) {
//    // Views should defer to their own implementation of
//    // setRowCount(int, bool)) per HasRows spec.
//    throw new Exception("UnsupportedOperationException");
//  }

  
  void setRowCount(int count, [bool isExact = true]) {
    if (count == getRowCount() && isExact == isRowCountExact()) {
      return;
    }
    _ensurePendingState().rowCount = count;
    _ensurePendingState().rowCountIsExact = isExact;

    // Update the cached data.
    _updateCachedData();

    // Update the pager.
    RowCountChangeEvent.fire(_display, count, isExact);
  }

  
  void setRowData(int start, List<T> values) {
    int valuesLength = values.length;
    int valuesEnd = start + valuesLength;

    // Calculate the bounded start (inclusive) and end index (exclusive).
    int pageStart = _getPageStart();
    int pageEnd = _getPageStart() + _getPageSize();
    int boundedStart = math.max(start, pageStart);
    int boundedEnd = math.min(valuesEnd, pageEnd);
    if (start != pageStart && boundedStart >= boundedEnd) {
      // The data is out of range for the current page.
      // Intentionally allow empty lists that start on the page start.
      return;
    }

    // Create placeholders up to the specified index.
    HasDataPresenterPendingState<T> pending = _ensurePendingState();
    int cacheOffset = math.max(0, boundedStart - pageStart - getVisibleItemCount());
    for (int i = 0; i < cacheOffset; i++) {
      pending.rowData.add(null);
    }

    // Insert the new values into the data array.
    for (int i = boundedStart; i < boundedEnd; i++) {
      T value = values[i - start];
      int dataIndex = i - pageStart;
      if (dataIndex < getVisibleItemCount()) {
        pending.rowData[dataIndex] = value;
      } else {
        pending.rowData.add(value);
      }
    }

    // Remember the range that has been replaced.
    pending.replaceRange(boundedStart - cacheOffset, boundedEnd);

    // Fire a row count change event after updating the data.
    if (valuesEnd > getRowCount()) {
      setRowCount(valuesEnd, isRowCountExact());
    }
  }

  
  void setSelectionModel(SelectionModel<T> selectionModel) {
    clearSelectionModel();

    // Set the new selection model.
    this._selectionModel = selectionModel;
    if (_selectionModel != null) {
      _selectionHandler = _selectionModel.addSelectionChangeHandler(new SelectionChangeEventHandlerAdapter((SelectionChangeEvent evt) {
        // Ensure that we resolve selection.
        _ensurePendingState();
      }));
    }

    // Update the current selection state based on the new model.
    _ensurePendingState();
  }

  /**
   * @throws UnsupportedOperationException
   */
  
  void setVisibleRange(int start, int length) {
    // Views should defer to their own implementation of setVisibleRange(Range)
    // per HasRows spec.
    throw new Exception("UnsupportedOperationException");
  }

  
  void setVisibleRangeByRange(Range range) {
    _setVisibleRange(range, false, false);
  }

  
  void setVisibleRangeAndClearData(Range range, bool forceRangeChangeEvent) {
    _setVisibleRange(range, true, forceRangeChangeEvent);
  }

  /**
   * Schedules the command.
   * 
   * <p>
   * Protected so that subclasses can override to use an alternative scheduler.
   * </p>
   * 
   * @param command the command to execute
   */
  void scheduleFinally(scheduler.ScheduledCommand command) {
    //scheduler.Scheduler.get().scheduleFinally(command);
    scheduler.Scheduler.get().scheduleDeferred(command);
  }

  /**
   * Combine the modified row indexes into as many as two {@link Range}s,
   * optimizing to have the fewest unmodified rows within the ranges. Using two
   * ranges covers the most common use cases of selecting one row, selecting a
   * range, moving selection from one row to another, or moving keyboard
   * selection.
   * 
   * <p>
   * Visible for testing.
   * </p>
   * 
   * <p>
   * This method has the side effect of sorting the modified rows.
   * </p>
   * 
   * @param modifiedRows the unordered indexes of modified rows
   * @return up to two ranges that encompass the modified rows
   */
  List<Range> calculateModifiedRanges(List<int> modifiedRows, int pageStart, int pageEnd) {
    sortJsArrayInteger(modifiedRows);

    int rangeStart0 = -1;
    int rangeEnd0 = -1;
    int rangeStart1 = -1;
    int rangeEnd1 = -1;
    int maxDiff = 0;
    for (int i = 0; i < modifiedRows.length; i++) {
      int index = modifiedRows[i];
      if (index < pageStart || index >= pageEnd) {
        // The index is out of range of the current page.
        continue;
      } else if (rangeStart0 == -1) {
        // Range0 defaults to the first index.
        rangeStart0 = index;
        rangeEnd0 = index;
      } else if (rangeStart1 == -1) {
        // Range1 defaults to the second index.
        maxDiff = index - rangeEnd0;
        rangeStart1 = index;
        rangeEnd1 = index;
      } else {
        int diff = index - rangeEnd1;
        if (diff > maxDiff) {
          // Move the old range1 onto range0 and start range1 from this index.
          rangeEnd0 = rangeEnd1;
          rangeStart1 = index;
          rangeEnd1 = index;
          maxDiff = diff;
        } else {
          // Add this index to range1.
          rangeEnd1 = index;
        }
      }
    }

    // Convert the range ends to exclusive indexes for calculations.
    rangeEnd0 += 1;
    rangeEnd1 += 1;

    // Combine the ranges if they are continuous.
    if (rangeStart1 == rangeEnd0) {
      rangeEnd0 = rangeEnd1;
      rangeStart1 = -1;
      rangeEnd1 = -1;
    }

    // Return the ranges.
    List<Range> toRet = new List<Range>();
    if (rangeStart0 != -1) {
      int rangeLength0 = rangeEnd0 - rangeStart0;
      toRet.add(new Range(rangeStart0, rangeLength0));
    }
    if (rangeStart1 != -1) {
      int rangeLength1 = rangeEnd1 - rangeStart1;
      toRet.add(new Range(rangeStart1, rangeLength1));
    }
    return toRet;
  }

  /**
   * Ensure that a pending {@link _HasDataPresenterDefaultState} exists and return it.
   * 
   * @return the pending state
   */
  HasDataPresenterPendingState<T> _ensurePendingState() {
    // Create the pending state if needed.
    if (_pendingState == null) {
      _pendingState = new HasDataPresenterPendingState<T>(_state);
    }

    /*
     * Schedule a command to resolve the pending state. If a command is already
     * scheduled, we reschedule a new one to ensure that it happens after any
     * existing finally commands (such as SelectionModel commands).
     */
    _pendingStateCommand = new _HasDataPresenterPendingStateScheduledCommand(this);
    scheduleFinally(_pendingStateCommand);

    // Return the pending state.
    return _pendingState;
  }

  /**
   * Find the index within the {@link HasDataPresenterState} of the best match for the specified
   * row value. The best match is a row value with the same key, closest to the
   * initial index.
   * 
   * @param state the state to search
   * @param value the value to find
   * @param initialIndex the initial index of the value
   * @return the best match index, or -1 if not found
   */
  int _findIndexOfBestMatch(HasDataPresenterState<T> state, T value, int initialIndex) {
    // Get the key for the value.
    var key = _getRowValueKey(value);
    if (key == null) {
      return -1;
    }

    int bestMatchIndex = -1;
    int bestMatchDiff = 0x7FFFFFFF; //MAX_VALUE
    int rowDataCount = state.getRowDataSize();
    for (int i = 0; i < rowDataCount; i++) {
      T curValue = state.getRowDataValue(i);
      var curKey = _getRowValueKey(curValue);
      if (key.equals(curKey)) {
        int diff = (initialIndex - i).abs();
        if (diff < bestMatchDiff) {
          bestMatchIndex = i;
          bestMatchDiff = diff;
        }
      }
    }
    return bestMatchIndex;
  }

  /**
   * Get the current state of the presenter.
   * 
   * @return the pending state if one exists, otherwise the state
   */
  HasDataPresenterState<T> _getCurrentState() {
    return _pendingState == null ? _state : _pendingState;
  }

  int _getPageSize() {
    return _getCurrentState().getPageSize();
  }

  int _getPageStart() {
    return _getCurrentState().getPageStart();
  }

  /**
   * Get the key for the specified row value.
   * 
   * @param rowValue the row value
   * @return the key
   */
  Object _getRowValueKey(T rowValue) {
    return (_keyProvider == null || rowValue == null) ? rowValue : _keyProvider.getKey(rowValue);
  }

  /**
   * Resolve the pending state and push updates to the view.
   * 
   * @param modifiedRows the modified rows that need to be updated, or null if
   *          none. The modified rows may be mutated.
   * @return true if the state changed, false if not
   */
  bool _resolvePendingState(List<int> modifiedRows) {
    _pendingStateCommand = null;

    /*
     * We are already resolving state. New changes will be flushed after the
     * current flush is finished.
     */
    if (_isResolvingState) {
      return false;
    }
    _isResolvingState = true;

    // Early exit if there is no pending state.
    if (_pendingState == null) {
      _isResolvingState = false;
      _pendingStateLoop = 0;
      return false;
    }

    /*
     * Check for an infinite loop. This can happen if user code accessed in this
     * method modifies the pending state and flushes changes.
     */
    _pendingStateLoop++;
    if (_pendingStateLoop > _LOOP_MAXIMUM) {
      _isResolvingState = false;
      _pendingStateLoop = 0; // Let user code handle exception and try again.
      throw new Exception(
          "A possible infinite loop has been detected in a Cell Widget. This "
              + "usually happens when your SelectionModel triggers a "
              + "SelectionChangeEvent when SelectionModel.isSelection() is "
              + "called, which causes the table to redraw continuously.");
    }

    /*
     * Swap the states in case user code triggers more changes, which will
     * create a new pendingState.
     */
    HasDataPresenterState<T> oldState = _state;
    HasDataPresenterPendingState<T> newState = _pendingState;
    _state = _pendingState;
    _pendingState = null;

    /*
     * Keep track of the absolute indexes of modified rows.
     * 
     * Use a native array to avoid dynamic casts associated with emulated Java
     * Collections.
     */
    if (modifiedRows == null) {
      modifiedRows = new List<int>(); // JavaScriptObject.createArray().cast();
    }

    // Get the values used for calculations.
    int pageStart = newState.getPageStart();
    int pageSize = newState.getPageSize();
    int pageEnd = pageStart + pageSize;
    int rowDataCount = newState.getRowDataSize();

    /*
     * Resolve keyboard selection. If the row value still exists, use its index.
     * If the row value exists in multiple places, use the closest index. If the
     * row value no longer exists, use the current index.
     */
    newState.keyboardSelectedRow =
        math.max(0, math.min(newState.keyboardSelectedRow, rowDataCount - 1));
    if (KeyboardSelectionPolicy.DISABLED == _keyboardSelectionPolicy) {
      // Clear the keyboard selected state.
      newState.keyboardSelectedRow = 0;
      newState.keyboardSelectedRowValue = null;
    } else if (newState._keyboardSelectedRowChanged) {
      // Choose the row value based on the index.
      newState.keyboardSelectedRowValue =
          rowDataCount > 0 ? newState.getRowDataValue(newState.keyboardSelectedRow) : null;
    } else if (newState.keyboardSelectedRowValue != null) {
      // Choose the index based on the row value.
      int bestMatchIndex =
          _findIndexOfBestMatch(newState, newState.keyboardSelectedRowValue,
              newState.keyboardSelectedRow);
      if (bestMatchIndex >= 0) {
        // A match was found.
        newState.keyboardSelectedRow = bestMatchIndex;
        newState.keyboardSelectedRowValue =
            rowDataCount > 0 ? newState.getRowDataValue(newState.keyboardSelectedRow) : null;
      } else {
        // No match was found, so reset to 0.
        newState.keyboardSelectedRow = 0;
        newState.keyboardSelectedRowValue = null;
      }
    }

    /*
     * Update the SelectionModel based on the keyboard selected value. We only
     * bind to selection after the user has interacted with the widget at least
     * once. This prevents values from being selected by default.
     */
    try {
      if (KeyboardSelectionPolicy.BOUND_TO_SELECTION == _keyboardSelectionPolicy
          && _selectionModel != null && newState.viewTouched) {
        T oldValue = oldState.getSelectedValue();
        Object oldKey = _getRowValueKey(oldValue);
        T newValue =
            rowDataCount > 0 ? newState.getRowDataValue(newState.getKeyboardSelectedRow()) : null;
        Object newKey = _getRowValueKey(newValue);
        /*
         * Do not deselect the old value unless we have a new value to select,
         * or we will have a null selection event while we wait for asynchronous
         * data to load.
         */
        if (newKey != null) {
          // Check both values for selection before setting selection, or the
          // selection model may resolve state early.
          bool oldValueWasSelected =
              (oldValue == null) ? false : _selectionModel.isSelected(oldValue);
          bool newValueWasSelected =
              (newValue == null) ? false : _selectionModel.isSelected(newValue);

          if (newKey != oldKey) {
            // Deselect the old value.
            if (oldValueWasSelected) {
              _selectionModel.setSelected(oldValue, false);
            }

            // Select the new value.
            newState.selectedValue = newValue;
            if (newValue != null && !newValueWasSelected) {
              _selectionModel.setSelected(newValue, true);
            }
          } else if (!newValueWasSelected) {
            // The value was programmatically deselected.
            newState.selectedValue = null;
          }
        }
      }
    } on Exception catch (e) {
      // Unlock the rendering loop if the user SelectionModel throw an error.
      _isResolvingState = false;
      _pendingStateLoop = 0;
      throw e;
    }

    // If the keyboard row changes, add it to the modified set.
    bool keyboardRowChanged =
        newState._keyboardSelectedRowChanged
            || (oldState.getKeyboardSelectedRow() != newState.keyboardSelectedRow)
            || (oldState.getKeyboardSelectedRowValue() == null && newState.keyboardSelectedRowValue != null);

    /*
     * Resolve selection. Check the selection status of all row values in the
     * pending state and compare them to the status in the old state. If we know
     * longer have a SelectionModel but had selected rows, we still need to
     * update the rows.
     */
    Set<int> newlySelectedRows = new Set<int>();
    try {
      for (int i = pageStart; i < pageStart + rowDataCount; i++) {
        // Check the new selection state.
        T rowValue = newState.getRowDataValue(i - pageStart);
        bool isSelected =
            (rowValue != null && _selectionModel != null && _selectionModel.isSelected(rowValue));

        // Compare to the old selection state.
        bool wasSelected = oldState.isRowSelected(i);
        if (isSelected) {
          newState.selectedRows.add(i);
          newlySelectedRows.add(i);
          if (!wasSelected) {
            modifiedRows.add(i);
          }
        } else if (wasSelected) {
          modifiedRows.add(i);
        }
      }
    } on Exception catch (e) {
      // Unlock the rendering loop if the user SelectionModel throw an error.
      _isResolvingState = false;
      _pendingStateLoop = 0;
      throw e;
    }

    // Add the replaced ranges as modified rows.
    bool replacedEmptyRange = false;
    for (Range replacedRange in newState._replacedRanges) {
      int start = replacedRange.getStart();
      int length = replacedRange.getLength();
      // If the user set an empty range, pass it through to the view.
      if (length == 0) {
        replacedEmptyRange = true;
      }
      for (int i = start; i < start + length; i++) {
        modifiedRows.add(i);
      }
    }

    // Add keyboard rows to modified rows if we are going to render anyway.
    if (modifiedRows.length > 0 && keyboardRowChanged) {
      modifiedRows.add(oldState.getKeyboardSelectedRow());
      modifiedRows.add(newState.keyboardSelectedRow);
    }

    /*
     * We called methods in user code that could modify the view, so early exit
     * if there is a new pending state waiting to be resolved.
     */
    if (_pendingState != null) {
      _isResolvingState = false;
      // Do not reset _pendingStateLoop, or we will not detect the infinite loop.

      // Propagate modifications to the temporary pending state into the new
      // pending state instance.
      _pendingState.selectedValue = newState.selectedValue;
      _pendingState.selectedRows.addAll(newlySelectedRows);
      if (keyboardRowChanged) {
        _pendingState._keyboardSelectedRowChanged = true;
      }
      if (newState._keyboardStealFocus) {
        _pendingState._keyboardStealFocus = true;
      }

      /*
       * Add the keyboard selected rows to the modified rows so they can be
       * re-rendered in the new state. These rows may already be added, but
       * modifiedRows can contain duplicates.
       */
      modifiedRows.add(oldState.getKeyboardSelectedRow());
      modifiedRows.add(newState.keyboardSelectedRow);

      /*
       * Make a recursive call to resolve the state again, using the new pending
       * state that was just created. If we are successful, then the modified
       * rows will be redrawn. If we are not successful, then we still need to
       * redraw the modified rows.
       */
      if (_resolvePendingState(modifiedRows)) {
        return true;
      }
    }

    // Calculate the modified ranges.
    List<Range> modifiedRanges = calculateModifiedRanges(modifiedRows, pageStart, pageEnd);
    Range range0 = modifiedRanges.length > 0 ? modifiedRanges[0] : null;
    Range range1 = modifiedRanges.length > 1 ? modifiedRanges[1] : null;
    int replaceDiff = 0; // The total number of rows to replace.
    for (Range range in modifiedRanges) {
      replaceDiff += range.getLength();
    }

    /*
     * Check the various conditions that require redraw.
     */
    int oldPageStart = oldState.getPageStart();
    int oldPageSize = oldState.getPageSize();
    int oldRowDataCount = oldState.getRowDataSize();
    bool redrawRequired = newState._redrawRequired;
    if (pageStart != oldPageStart) {
      // Redraw if pageStart changes.
      redrawRequired = true;
    } else if (rowDataCount < oldRowDataCount) {
      // Redraw if we have trimmed the row data.
      redrawRequired = true;
    } else if (range1 == null && range0 != null && range0.getStart() == pageStart
        && (replaceDiff >= oldRowDataCount || replaceDiff > oldPageSize)) {
      // Redraw if the new data completely overlaps the old data.
      redrawRequired = true;
    } else if (replaceDiff >= _REDRAW_MINIMUM && replaceDiff > _REDRAW_THRESHOLD * oldRowDataCount) {
      /*
       * Redraw if the number of modified rows represents a large portion of the
       * view, defined as greater than 30% of the rows (minimum of 5).
       */
      redrawRequired = true;
    } else if (replacedEmptyRange && oldRowDataCount == 0) {
      /*
       * If the user replaced an empty range, pass it to the view. This is a
       * useful edge case that provides consistency in the way data is pushed to
       * the view.
       */
      redrawRequired = true;
    }

    // Update the loading state in the view.
    _updateLoadingState();

    /*
     * Push changes to the view.
     */
    try {
      if (redrawRequired) {
        // Redraw the entire content.
        util.SafeHtmlBuilder sb = new util.SafeHtmlBuilder();
        _view.replaceAllChildren(newState.rowData, _selectionModel, newState._keyboardStealFocus);
        _view.resetFocus();
      } else if (range0 != null) {
        // Surgically replace specific rows.

        // Replace range0.
        {
          int absStart = range0.getStart();
          int relStart = absStart - pageStart;
          util.SafeHtmlBuilder sb = new util.SafeHtmlBuilder();
          List<T> replaceValues = newState.rowData.sublist(relStart, relStart + range0.getLength());
          _view.replaceChildren(replaceValues, relStart, _selectionModel, newState._keyboardStealFocus);
        }

        // Replace range1 if it exists.
        if (range1 != null) {
          int absStart = range1.getStart();
          int relStart = absStart - pageStart;
          util.SafeHtmlBuilder sb = new util.SafeHtmlBuilder();
          List<T> replaceValues = newState.rowData.sublist(relStart, relStart + range1.getLength());
          _view.replaceChildren(replaceValues, relStart, _selectionModel, newState._keyboardStealFocus);
        }

        _view.resetFocus();
      } else if (keyboardRowChanged) {
        // Update the keyboard selected rows without redrawing.
        // Deselect the old keyboard row.
        int oldSelectedRow = oldState.getKeyboardSelectedRow();
        if (oldSelectedRow >= 0 && oldSelectedRow < rowDataCount) {
          _view.setKeyboardSelected(oldSelectedRow, false, false);
        }

        // Select the new keyboard row.
        int newSelectedRow = newState.getKeyboardSelectedRow();
        if (newSelectedRow >= 0 && newSelectedRow < rowDataCount) {
          _view.setKeyboardSelected(newSelectedRow, true, newState._keyboardStealFocus);
        }
      }
    } on Exception catch (e) {
      // Force the error into the dev mode console.
      throw new Exception(e);
    } finally {
      /*
       * We are done resolving state, so unlock the rendering loop. We unlock
       * the loop even if user rendering code throws an error to avoid throwing
       * an additional, misleading IllegalStateException.
       */
      _isResolvingState = false;
    }

    /*
     * Make a recursive call to resolve any pending state. We don't expect
     * pending state here, but its always possible that pushing the changes into
     * the view could update the presenter. If there is no new state, the
     * recursive call will reset the _pendingStateLoop.
     */
    _resolvePendingState(null);
    return true;
  }

  /**
   * Set the visible {@link Range}, optionally clearing data and/or firing a
   * {@link RangeChangeEvent}.
   * 
   * @param range the new {@link Range}
   * @param clearData true to clear all data
   * @param forceRangeChangeEvent true to force a {@link RangeChangeEvent}
   */
  void _setVisibleRange(Range range, [bool clearData = false, bool forceRangeChangeEvent = false]) {
    final int start = range.getStart();
    final int length = range.getLength();
    if (start < 0) {
      throw new Exception("Range start cannot be less than 0");
    }
    if (length < 0) {
      throw new Exception("Range length cannot be less than 0");
    }

    // Update the page start.
    final int pageStart = _getPageStart();
    final int pageSize = _getPageSize();
    final bool pageStartChanged = (pageStart != start);
    if (pageStartChanged) {
      HasDataPresenterPendingState<T> pending = _ensurePendingState();

      // Trim the data if we aren't clearing it.
      if (!clearData) {
        if (start > pageStart) {
          int increase = start - pageStart;
          if (getVisibleItemCount() > increase) {
            // Remove the data we no longer need.
            for (int i = 0; i < increase; i++) {
              pending.rowData.remove(0);
            }
          } else {
            // We have no overlapping data, so just clear it.
            pending.rowData.clear();
          }
        } else {
          int decrease = pageStart - start;
          if ((getVisibleItemCount() > 0) && (decrease < pageSize)) {
            // Insert null data at the beginning.
            for (int i = 0; i < decrease; i++) {
              pending.rowData.insert(0, null);
            }

            // Remember the inserted range because we might return to the same
            // pageStart in this event loop, which means we won't do a full
            // redraw, but still need to replace the inserted nulls in the view.
            pending.replaceRange(start, start + decrease);
          } else {
            // We have no overlapping data, so just clear it.
            pending.rowData.clear();
          }
        }
      }

      // Update the page start.
      pending.pageStart = start;
    }

    // Update the page size.
    bool pageSizeChanged = (pageSize != length);
    if (pageSizeChanged) {
      _ensurePendingState().pageSize = length;
    }

    // Clear the data.
    if (clearData) {
      _ensurePendingState().rowData.clear();
    }

    // Trim the row values if needed.
    _updateCachedData();

    // Update the pager and data source if the range changed.
    if (pageStartChanged || pageSizeChanged || forceRangeChangeEvent) {
      RangeChangeEvent.fire(_display, getVisibleRange());
    }
  }

  /**
   * Ensure that the cached data is consistent with the data size.
   */
  void _updateCachedData() {
    int pageStart = _getPageStart();
    int expectedLastIndex = math.max(0, math.min(_getPageSize(), getRowCount() - pageStart));
    int lastIndex = getVisibleItemCount() - 1;
    while (lastIndex >= expectedLastIndex) {
      _ensurePendingState().rowData.remove(lastIndex);
      lastIndex--;
    }
  }

  /**
   * Update the loading state of the view based on the data size and page size.
   */
  void _updateLoadingState() {
    int cacheSize = getVisibleItemCount();
    int curPageSize = isRowCountExact() ? getCurrentPageSize() : _getPageSize();
    if (cacheSize >= curPageSize) {
      _view.setLoadingState(LoadingState.LOADED);
    } else if (cacheSize == 0) {
      _view.setLoadingState(LoadingState.LOADING);
    } else {
      _view.setLoadingState(LoadingState.PARTIALLY_LOADED);
    }
  }
}


/**
 * An iterator over DOM elements.
 */
abstract class ElementIterator extends Iterator {
  /**
   * Set the selection state of the current element.
   * 
   * @param selected the selection state
   * @throws IllegalStateException if {@link #next()} has not been called
   */
  void setSelected(bool selected);
}

/**
 * The view that this presenter presents.
 * 
 * @param <T> the data type
 */
abstract class HasDataPresenterView<T> {

  /**
   * Add a handler to the view.
   * 
   * @param <H> the handler type
   * @param handler the handler to add
   * @param type the event type
   */
  event.HandlerRegistration addHandler(handler, event.EventType type);

  /**
   * Replace all children with the specified values.
   * 
   * @param values the values of the new children
   * @param selectionModel the {@link SelectionModel}
   * @param stealFocus true if the row should steal focus, false if not
   */
  void replaceAllChildren(List<T> values, SelectionModel<T> selectionModel,
      bool stealFocus);

  /**
   * Replace existing elements starting at the specified index. If the number
   * of children specified exceeds the existing number of children, the
   * remaining children should be appended.
   * 
   * @param values the values of the new children
   * @param start the start index to be replaced, relative to the pageStart
   * @param selectionModel the {@link SelectionModel}
   * @param stealFocus true if the row should steal focus, false if not
   */
  void replaceChildren(List<T> values, int start, SelectionModel<T> selectionModel,
      bool stealFocus);

  /**
   * Re-establish focus on an element within the view if the view already had
   * focus.
   */
  void resetFocus();

  /**
   * Update an element to reflect its keyboard selected state.
   * 
   * @param index the index of the element relative to page start
   * @param selected true if selected, false if not
   * @param stealFocus true if the row should steal focus, false if not
   */
  void setKeyboardSelected(int index, bool selected, bool stealFocus);

  /**
   * Set the current loading state of the data.
   * 
   * @param state the loading state
   */
  void setLoadingState(LoadingState state);
}

/**
 * Represents the state of the presenter.
 * 
 * @param <T> the data type of the presenter
 */
class _HasDataPresenterDefaultState<T> implements HasDataPresenterState<T> {
  int keyboardSelectedRow = 0;
  T keyboardSelectedRowValue = null;
  int pageSize;
  int pageStart = 0;
  int rowCount = 0;
  bool rowCountIsExact = false;
  final List<T> rowData = new List<T>();
  final Set<int> selectedRows = new Set<int>();
  T selectedValue = null;
  bool viewTouched;

  _HasDataPresenterDefaultState(int pageSize) {
    this.pageSize = pageSize;
  }

  
  int getKeyboardSelectedRow() {
    return keyboardSelectedRow;
  }

  
  T getKeyboardSelectedRowValue() {
    return keyboardSelectedRowValue;
  }

  
  int getPageSize() {
    return pageSize;
  }

  
  int getPageStart() {
    return pageStart;
  }

  
  int getRowCount() {
    return rowCount;
  }

  
  int getRowDataSize() {
    return rowData.length;
  }

  
  T getRowDataValue(int index) {
    return rowData[index];
  }

  
  List<T> getRowDataValues() {
    return new List<T>.from(rowData); //Collections.unmodifiableList(rowData);
  }

  
  T getSelectedValue() {
    return selectedValue;
  }

  
  bool isRowCountExact() {
    return rowCountIsExact;
  }

  /**
   * {@inheritDoc}
   * 
    * <p>
    * The set of selected rows is not maintained in the pending state. This
   * method should only be called on the state after it has been resolved.
   * </p>
   */
  
  bool isRowSelected(int index) {
    return selectedRows.contains(index);
  }

  
  bool isViewTouched() {
    return viewTouched;
  }
}

/**
 * Represents the pending state of the presenter.
 * 
 * @param <T> the data type of the presenter
 */
class HasDataPresenterPendingState<T> extends _HasDataPresenterDefaultState<T> {

  /**
   * A bool indicating that the user has keyboard selected a new row.
   */
  bool _keyboardSelectedRowChanged = false;

  /**
   * A bool indicating that a change in keyboard selected should cause us
   * to steal focus.
   */
  bool _keyboardStealFocus = false;

  /**
   * Set to true if a redraw is required.
   */
  bool _redrawRequired = false;

  /**
   * The list of ranges that have been replaced.
   */
  final List<Range> _replacedRanges = new List<Range>();

  HasDataPresenterPendingState(HasDataPresenterState<T> state) : super(state.getPageSize()) {
    this.keyboardSelectedRow = state.getKeyboardSelectedRow();
    this.keyboardSelectedRowValue = state.getKeyboardSelectedRowValue();
    this.pageSize = state.getPageSize();
    this.pageStart = state.getPageStart();
    this.rowCount = state.getRowCount();
    this.rowCountIsExact = state.isRowCountExact();
    this.selectedValue = state.getSelectedValue();
    this.viewTouched = state.isViewTouched();

    // Copy the row data.
    int rowDataSize = state.getRowDataSize();
    for (int i = 0; i < rowDataSize; i++) {
      this.rowData.add(state.getRowDataValue(i));
    }

    /*
     * We do not copy the selected rows from the old state. They will be
     * resolved from the SelectionModel.
     */
  }

  /**
   * Update the range of replaced data.
   * 
   * @param start the start index
   * @param end the end index
   */
  void replaceRange(int start, int end) {
    _replacedRanges.add(new Range(start, end - start));
  }
}

/**
 * Represents the state of the presenter.
 * 
 * @param <T> the data type of the presenter
 */
abstract class HasDataPresenterState<T> {
  /**
   * Get the current keyboard selected row relative to page start. This value
   * should never be negative.
   */
  int getKeyboardSelectedRow();

  /**
   * Get the last row value that was selected with the keyboard.
   */
  T getKeyboardSelectedRowValue();

  /**
   * Get the number of rows in the current page.
   */
  int getPageSize();

  /**
   * Get the absolute start index of the page.
   */
  int getPageStart();

  /**
   * Get the total number of rows.
   */
  int getRowCount();

  /**
   * Get the size of the row data.
   */
  int getRowDataSize();

  /**
   * Get a specific value from the row data.
   */
  T getRowDataValue(int index);

  /**
   * Get all of the row data values in an unmodifiable list.
   */
  List<T> getRowDataValues();

  /**
   * Get the value that is selected in the {@link SelectionModel}.
   */
  T getSelectedValue();

  /**
   * Get a bool indicating whether the row count is exact or an estimate.
   */
  bool isRowCountExact();

  /**
   * Check if a row index is selected.
   * 
   * @param index the row index
   * @return true if selected, false if not
   */
  bool isRowSelected(int index);

  /**
   * Check if the user interacted with the view at some point. Selection is
   * not bound to the keyboard selected row until the view is touched. Once
   * touched, selection is bound from then on.
   */
  bool isViewTouched();
}

class _HasDataPresenterPendingStateScheduledCommand implements scheduler.ScheduledCommand {

  HasDataPresenter _presenter;
  
  _HasDataPresenterPendingStateScheduledCommand(this._presenter);
  
  void execute() {
    // Verify that this command was the last one scheduled.
    if (_presenter._pendingStateCommand == this) {
      _presenter._resolvePendingState(null);
    }
  }
}