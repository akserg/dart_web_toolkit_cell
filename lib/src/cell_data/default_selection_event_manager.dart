//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * An implementation of {@link CellPreviewEvent.Handler} that adds selection
 * support via the spacebar and mouse clicks and handles the control key.
 * 
 * <p>
 * If the {@link HasData} source of the selection event uses a
 * {@link MultiSelectionModel}, this manager additionally provides support for
 * shift key to select a range of values. For all other {@link SelectionModel}s,
 * only the control key is supported.
 * </p>
 * 
 * @param <T> the data type of records in the list
 */
class DefaultSelectionEventManager<T> implements CellPreviewEventHandler<T> {

  /**
   * Construct a new {@link DefaultSelectionEventManager} that ignores selection
   * for the columns in the specified blacklist.
   * 
   * @param <T> the data type of the display
   * @param blacklistedColumns the columns to include in the blacklist
   * @return a {@link DefaultSelectionEventManager} instance
   */
  static DefaultSelectionEventManager createBlacklistManager(List<int> blacklistedColumns) {
    return new DefaultSelectionEventManager(new BlacklistEventTranslator(blacklistedColumns));
  }
  
  /**
   * Construct a new {@link DefaultSelectionEventManager} that triggers
   * selection when a checkbox in the specified column is clicked.
   * 
   * @param <T> the data type of the display
   * @param column the column to handle
   * @return a {@link DefaultSelectionEventManager} instance
   */
  static DefaultSelectionEventManager createCheckboxManager([int column = null]) {
    return new DefaultSelectionEventManager(new CheckboxEventTranslator(column));
  }

  /**
   * Create a new {@link DefaultSelectionEventManager} using the specified
   * {@link EventTranslator} to control which {@link SelectAction} to take for
   * each event.
   * 
   * @param <T> the data type of the display
   * @param _translator the {@link EventTranslator} to use
   * @return a {@link DefaultSelectionEventManager} instance
   */
  static DefaultSelectionEventManager createCustomManager(EventTranslator translator) {
    return new DefaultSelectionEventManager(translator);
  }

  /**
   * Create a new {@link DefaultSelectionEventManager} that handles selection
   * via user interactions.
   * 
   * @param <T> the data type of the display
   * @return a new {@link DefaultSelectionEventManager} instance
   */
  static DefaultSelectionEventManager createDefaultManager() {
    return new DefaultSelectionEventManager(null);
  }

  /**
   * Construct a new {@link DefaultSelectionEventManager} that allows selection
   * only for the columns in the specified whitelist.
   * 
   * @param <T> the data type of the display
   * @param whitelistedColumns the columns to include in the whitelist
   * @return a {@link DefaultSelectionEventManager} instance
   */
  static DefaultSelectionEventManager createWhitelistManager(List<int>  whitelistedColumns) {
    return new DefaultSelectionEventManager(new WhitelistEventTranslator(whitelistedColumns));
  }

  /**
   * The last {@link HasData} that was handled.
   */
  HasData<T> _lastDisplay;

  /**
   * The last page start.
   */
  int _lastPageStart = -1;

  /**
   * The last selected row index.
   */
  int _lastSelectedIndex = -1;

  /**
   * A bool indicating that the last shift selection was additive.
   */
  bool _shiftAdditive;

  /**
   * The last place where the user clicked without holding shift. Multi
   * selections that use the shift key are rooted at the anchor.
   */
  int _shiftAnchor = -1;

  /**
   * The {@link EventTranslator} that controls how selection is handled.
   */
  final EventTranslator<T> _translator;

  /**
   * Construct a new {@link DefaultSelectionEventManager} using the specified
   * {@link EventTranslator} to control which {@link SelectAction} to take for
   * each event.
   * 
   * @param _translator the {@link EventTranslator} to use
   */
  DefaultSelectionEventManager(this._translator);

  /**
   * Update the selection model based on a user selection event.
   * 
   * @param selectionModel the selection model to update
   * @param row the absolute index of the selected row
   * @param rowValue the selected row value
   * @param action the {@link SelectAction} to apply
   * @param selectRange true to select the range from the last selected row
   * @param clearOthers true to clear the current selection
   */
  void doMultiSelection(MultiSelectionModel<T> selectionModel,
      HasData<T> display, int row, T rowValue, SelectAction action,
      bool selectRange, bool clearOthers) {
    // Determine if we will add or remove selection.
    bool addToSelection = true;
    if (action != null) {
      switch (action) {
        case SelectAction.IGNORE:
          // Ignore selection.
          return;
        case SelectAction.SELECT:
          addToSelection = true;
          break;
        case SelectAction.DESELECT:
          addToSelection = false;
          break;
        case SelectAction.TOGGLE:
          addToSelection = !selectionModel.isSelected(rowValue);
          break;
      }
    }

    // Determine which rows will be newly selected.
    int pageStart = display.getVisibleRange().getStart();
    if (selectRange && pageStart == _lastPageStart && _lastSelectedIndex > -1
        && _shiftAnchor > -1 && display == _lastDisplay) {
      /*
       * Get the new shift bounds based on the existing shift anchor and the
       * selected row.
       */
      int start = math.min(_shiftAnchor, row); // Inclusive.
      int end = math.max(_shiftAnchor, row); // Inclusive.

      if (_lastSelectedIndex < start) {
        // Revert previous selection if the user reselects a smaller range.
        setRangeSelection(selectionModel, display, new Range(_lastSelectedIndex,
            start - _lastSelectedIndex), !_shiftAdditive, false);
      } else if (_lastSelectedIndex > end) {
        // Revert previous selection if the user reselects a smaller range.
        setRangeSelection(selectionModel, display, new Range(end + 1,
            _lastSelectedIndex - end), !_shiftAdditive, false);
      } else {
        // Remember if we are adding or removing rows.
        _shiftAdditive = addToSelection;
      }

      // Update the last selected row, but do not move the shift anchor.
      _lastSelectedIndex = row;

      // Select the range.
      setRangeSelection(selectionModel, display, new Range(start, end - start
          + 1), _shiftAdditive, clearOthers);
    } else {
      /*
       * If we are not selecting a range, save the last row and set the shift
       * anchor.
       */
      _lastDisplay = display;
      _lastPageStart = pageStart;
      _lastSelectedIndex = row;
      _shiftAnchor = row;
      selectOne(selectionModel, rowValue, addToSelection, clearOthers);
    }
  }

  void onCellPreview(CellPreviewEvent<T> evt) {
    // Early exit if selection is already handled or we are editing.
    if (evt.isCellEditing() || evt.isSelectionHandled()) {
      return;
    }

    // Early exit if we do not have a SelectionModel.
    HasData<T> display = evt.getDisplay();
    SelectionModel<T> selectionModel = display.getSelectionModel();
    if (selectionModel == null) {
      return;
    }

    // Check for user defined actions.
    SelectAction action = (_translator == null) ? SelectAction.DEFAULT
        : _translator.translateSelectionEvent(evt);

    // Handle the event based on the SelectionModel type.
    if (selectionModel is MultiSelectionModel) {
      // Add shift key support for MultiSelectionModel.
      handleMultiSelectionEvent(evt, action,
          selectionModel as MultiSelectionModel<T>);
    } else {
      // Use the standard handler.
      handleSelectionEvent(evt, action, selectionModel);
    }
  }

  /**
   * Removes all items from the selection.
   * 
   * @param selectionModel the {@link MultiSelectionModel} to clear
   */
  void clearSelection(MultiSelectionModel<T> selectionModel) {
    selectionModel.clear();
  }

  /**
   * Handle an event that could cause a value to be selected for a
   * {@link MultiSelectionModel}. This overloaded method adds support for both
   * the control and shift keys. If the shift key is held down, all rows between
   * the previous selected row and the current row are selected.
   * 
   * @param event the {@link CellPreviewEvent} that triggered selection
   * @param action the action to handle
   * @param selectionModel the {@link SelectionModel} to update
   */
  void handleMultiSelectionEvent(CellPreviewEvent<T> evt,
      SelectAction action, MultiSelectionModel<T> selectionModel) {
    dart_html.Event nativeEvent = evt.getNativeEvent();
    String type = nativeEvent.type;
    if (event.BrowserEvents.CLICK == type) {
      /*
       * Update selection on click. Selection is toggled only if the user
       * presses the ctrl key. If the user does not press the control key,
       * selection is additive.
       */
      bool shift = (nativeEvent as dart_html.KeyboardEvent).shiftKey;
      bool ctrlOrMeta = (nativeEvent as dart_html.KeyboardEvent).ctrlKey || (nativeEvent as dart_html.KeyboardEvent).metaKey;
      bool clearOthers = (_translator == null) ? !ctrlOrMeta
          : _translator.clearCurrentSelection(evt);
      if (action == null || action == SelectAction.DEFAULT) {
        action = ctrlOrMeta ? SelectAction.TOGGLE : SelectAction.SELECT;
      }
      doMultiSelection(selectionModel, evt.getDisplay(), evt.getIndex(),
          evt.getValue(), action, shift, clearOthers);
    } else if (event.BrowserEvents.KEYUP == type) {
      int keyCode = (nativeEvent as dart_html.KeyboardEvent).keyCode;
      if (keyCode == 32) {
        /*
         * Update selection when the space bar is pressed. The spacebar always
         * toggles selection, regardless of whether the control key is pressed.
         */
        bool shift = (nativeEvent as dart_html.KeyboardEvent).shiftKey;
        bool clearOthers = (_translator == null) ? false
            : _translator.clearCurrentSelection(evt);
        if (action == null || action == SelectAction.DEFAULT) {
          action = SelectAction.TOGGLE;
        }
        doMultiSelection(selectionModel, evt.getDisplay(), evt.getIndex(),
            evt.getValue(), action, shift, clearOthers);
      }
    }
  }

  /**
   * Handle an event that could cause a value to be selected. This method works
   * for any {@link SelectionModel}. Pressing the space bar or ctrl+click will
   * toggle the selection state. Clicking selects the row if it is not selected.
   * 
   * @param event the {@link CellPreviewEvent} that triggered selection
   * @param action the action to handle
   * @param selectionModel the {@link SelectionModel} to update
   */
  void handleSelectionEvent(CellPreviewEvent<T> evt,
      SelectAction action, SelectionModel<T> selectionModel) {
    // Handle selection overrides.
    T value = evt.getValue();
    if (action != null) {
      switch (action) {
        case SelectAction.IGNORE:
          return;
        case SelectAction.SELECT:
          selectionModel.setSelected(value, true);
          return;
        case SelectAction.DESELECT:
          selectionModel.setSelected(value, false);
          return;
        case SelectAction.TOGGLE:
          selectionModel.setSelected(value, !selectionModel.isSelected(value));
          return;
      }
    }

    // Handle default selection.
    dart_html.Event nativeEvent = evt.getNativeEvent();
    String type = nativeEvent.type;
    if (event.BrowserEvents.CLICK == type) {
      if ((nativeEvent as dart_html.MouseEvent).ctrlKey || (nativeEvent as dart_html.MouseEvent).metaKey) {
        // Toggle selection on ctrl+click.
        selectionModel.setSelected(value, !selectionModel.isSelected(value));
      } else {
        // Select on click.
        selectionModel.setSelected(value, true);
      }
    } else if (event.BrowserEvents.KEYUP == type) {
      // Toggle selection on space.
      int keyCode = (nativeEvent as dart_html.KeyboardEvent).keyCode;
      if (keyCode == 32) {
        selectionModel.setSelected(value, !selectionModel.isSelected(value));
      }
    }
  }

  /**
   * Selects the given item, optionally clearing any prior selection.
   * 
   * @param selectionModel the {@link MultiSelectionModel} to update
   * @param target the item to select
   * @param selected true to select, false to deselect
   * @param clearOthers true to clear all other selected items
   */
  void selectOne(MultiSelectionModel<T> selectionModel,
      T target, bool selected, bool clearOthers) {
    if (clearOthers) {
      clearSelection(selectionModel);
    }
    selectionModel.setSelected(target, selected);
  }

  /**
   * Select or deselect a range of row indexes, optionally deselecting all other
   * values.
   * 
   * @param selectionModel the {@link MultiSelectionModel} to update
   * @param display the {@link HasData} source of the selection event
   * @param range the {@link Range} of rows to select or deselect
   * @param addToSelection true to select, false to deselect the range
   * @param clearOthers true to deselect rows not in the range
   */
  void setRangeSelection(
      MultiSelectionModel<T> selectionModel, HasData<T> display,
      Range range, bool addToSelection, bool clearOthers) {
    // Get the list of values to select.
    List<T> toUpdate = new List<T>();
    int itemCount = display.getVisibleItemCount();
    int relativeStart = range.getStart() - display.getVisibleRange().getStart();
    int relativeEnd = relativeStart + range.getLength();
    for (int i = relativeStart; i < relativeEnd && i < itemCount; i++) {
      toUpdate.add(display.getVisibleItem(i));
    }

    // Clear all other values.
    if (clearOthers) {
      clearSelection(selectionModel);
    }

    // Update the state of the values.
    for (T value in toUpdate) {
      selectionModel.setSelected(value, addToSelection);
    }
  }
}

/**
 * An event _translator that disables selection for the specified blacklisted
 * columns.
 * 
 * @param <T> the data type
 */
class BlacklistEventTranslator<T> implements EventTranslator<T> {
  final Set<int> blacklist = new Set<int>();

  /**
   * Construct a new {@link BlacklistEventTranslator}.
   * 
   * @param blacklistedColumns the columns to blacklist
   */
  BlacklistEventTranslator(List<int> blacklistedColumns) {
    if (blacklistedColumns != null) {
      for (int i in blacklistedColumns) {
        setColumnBlacklisted(i, true);
      }
    }
  }

  /**
   * Clear all columns from the blacklist.
   */
  void clearBlacklist() {
    blacklist.clear();
  }

  bool clearCurrentSelection(CellPreviewEvent<T> evt) {
    return false;
  }

  /**
   * Check if the specified column is blacklisted.
   * 
   * @param index the column index
   * @return true if blacklisted, false if not
   */
  bool isColumnBlacklisted(int index) {
    return blacklist.contains(index);
  }

  /**
   * Set whether or not the specified column in blacklisted.
   * 
   * @param index the column index
   * @param isBlacklisted true to blacklist, false to allow selection
   */
  void setColumnBlacklisted(int index, bool isBlacklisted) {
    if (isBlacklisted) {
      blacklist.add(index);
    } else {
      blacklist.remove(index);
    }
  }

  SelectAction translateSelectionEvent(CellPreviewEvent<T> evt) {
    return isColumnBlacklisted(evt.getColumn()) ? SelectAction.IGNORE
        : SelectAction.DEFAULT;
  }
}

/**
 * Implementation of {@link EventTranslator} that only triggers selection when
 * any checkbox is selected.
 * 
 * @param <T> the data type
 */
class CheckboxEventTranslator<T> implements EventTranslator<T> {

  /**
   * The column index of the checkbox. Other columns are ignored.
   */
  final int _column;

  /**
   * Construct a new {@link CheckboxEventTranslator} that will trigger
   * selection when a checkbox in the specified column is selected.
   * 
   * @param column the column index, or -1 for all columns
   */
  CheckboxEventTranslator([this._column = -1]);

  bool clearCurrentSelection(CellPreviewEvent<T> evt) {
    return false;
  }

  SelectAction translateSelectionEvent(CellPreviewEvent<T> evt) {
    // Handle the event.
    dart_html.Event nativeEvent = evt.getNativeEvent();
    if (event.BrowserEvents.CLICK == nativeEvent.type) {
      // Ignore if the event didn't occur in the correct column.
      if (_column > -1 && _column != evt.getColumn()) {
        return SelectAction.IGNORE;
      }

      // Determine if we clicked on a checkbox.
      dart_html.Element target = nativeEvent.target as dart_html.Element;
      if ("input" == target.tagName.toLowerCase()) {
        dart_html.InputElement input = target as dart_html.InputElement;
        if ("checkbox" == input.type.toLowerCase()) {
          // Synchronize the checkbox with the current selection state.
          input.checked = evt.getDisplay().getSelectionModel().isSelected(
              evt.getValue());
          return SelectAction.TOGGLE;
        }
      }
      return SelectAction.IGNORE;
    }

    // For keyboard events, do the default action.
    return SelectAction.DEFAULT;
  }
}

/**
 * Translates {@link CellPreviewEvent}s into {@link SelectAction}s.
 */
abstract class EventTranslator<T> {
  /**
   * Check whether a user selection event should clear all currently selected
   * values.
   * 
   * @param event the {@link CellPreviewEvent} to translate
   */
  bool clearCurrentSelection(CellPreviewEvent<T> evt);

  /**
   * Translate the user selection event into a {@link SelectAction}.
   * 
   * @param event the {@link CellPreviewEvent} to translate
   */
  SelectAction translateSelectionEvent(CellPreviewEvent<T> evt);
}

/**
 * The action that controls how selection is handled.
 */
class SelectAction<int> extends util.Enum<int> {

  const SelectAction(int type) : super (type);

  // Perform the default action.
  static const SelectAction DEFAULT = const SelectAction(0);
  // Select the value.
  static const SelectAction SELECT = const SelectAction(1);
  // Deselect the value.
  static const SelectAction DESELECT = const SelectAction(2);
  // Toggle the selected state of the value.
  static const SelectAction TOGGLE = const SelectAction(3);
  // Ignore the event.
  static const SelectAction IGNORE = const SelectAction(4);
}

/**
 * An event _translator that allows selection only for the specified
 * whitelisted columns.
 * 
 * @param <T> the data type
 */
class WhitelistEventTranslator<T> implements EventTranslator<T> {
  final Set<int> whitelist = new Set<int>();

  /**
   * Construct a new {@link WhitelistEventTranslator}.
   * 
   * @param whitelistedColumns the columns to whitelist
   */
  WhitelistEventTranslator(List<int> whitelistedColumns) {
    if (whitelistedColumns != null) {
      for (int i in whitelistedColumns) {
        setColumnWhitelisted(i, true);
      }
    }
  }

  bool clearCurrentSelection(CellPreviewEvent<T> evt) {
    return false;
  }

  /**
   * Clear all columns from the whitelist.
   */
  void clearWhitelist() {
    whitelist.clear();
  }

  /**
   * Check if the specified column is whitelisted.
   * 
   * @param index the column index
   * @return true if whitelisted, false if not
   */
  bool isColumnWhitelisted(int index) {
    return whitelist.contains(index);
  }

  /**
   * Set whether or not the specified column in whitelisted.
   * 
   * @param index the column index
   * @param isWhitelisted true to whitelist, false to allow disallow selection
   */
  void setColumnWhitelisted(int index, bool isWhitelisted) {
    if (isWhitelisted) {
      whitelist.add(index);
    } else {
      whitelist.remove(index);
    }
  }

  SelectAction translateSelectionEvent(CellPreviewEvent<T> evt) {
    return isColumnWhitelisted(evt.getColumn()) ? SelectAction.DEFAULT
        : SelectAction.IGNORE;
  }
}
