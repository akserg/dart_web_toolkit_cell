//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * A simple selection model that allows multiple items to be selected.
 * 
 * @param <T> the data type of the items
 */
class MultiSelectionModel<T> extends AbstractSelectionModel<T>
    implements SetSelectionModel<T> {

  // Ensure one value per key
  Map<Object, T> selectedSet;

  /**
   * A map of keys to the item and its pending selection state.
   */
  Map<Object, SelectionChange<T>> _selectionChanges;

  /**
   * Construct a MultiSelectionModel with the given key provider and
   * implementations of selectedSet and selectionChanges. Different
   * implementations allow for enforcing order on selection.
   * 
   * @param keyProvider an instance of data.ProvidesKey<T>, or null if the item
   *          should act as its own key
   * @param selectedSet an instance of Map
   * @param selectionChanges an instance of Map
   */
  MultiSelectionModel([data.ProvidesKey<T> keyProvider = null, 
          this.selectedSet = null, 
          this._selectionChanges = null]) : 
            super(keyProvider) {
    if (this.selectedSet == null) {
      this.selectedSet = new Map<Object, T>();
    }
    if (this._selectionChanges == null) {
      this._selectionChanges = new Map<Object, SelectionChange<T>>();
    }
  }

  /**
   * Deselect all selected values.
   */
  
  void clear() {
    // Clear the current list of pending changes.
    _selectionChanges.clear();

    /*
     * Add a pending change to deselect each key that is currently selected. We
     * cannot just clear the selected set, because then we would not know which
     * keys were selected before we cleared, which we need to know to determine
     * if we should fire an event.
     */
    for (T value in selectedSet.values) {
      _selectionChanges[getKey(value)] = new SelectionChange<T>(value, false);
    }
    scheduleSelectionChangeEvent();
  }

  /**
   * Get the set of selected items as a copy. If multiple selected items share
   * the same key, only the last selected item is included in the set.
   * 
   * @return the set of selected items
   */
  
  Set<T> getSelectedSet() {
    resolveChanges();
    return new Set<T>.from(selectedSet.values);
  }

  
  bool isSelected(T item) {
    resolveChanges();
    return selectedSet.containsKey(getKey(item));
  }

  
  void setSelected(T item, bool selected) {
    _selectionChanges[getKey(item)] = new SelectionChange<T>(item, selected);
    scheduleSelectionChangeEvent();
  }

  
  void fireSelectionChangeEvent() {
    if (isEventScheduled()) {
      setEventCancelled(true);
    }
    resolveChanges();
  }

  void resolveChanges() {
    if (_selectionChanges.isEmpty) {
      return;
    }

    bool changed = false;
    
    for (Object key in _selectionChanges.keys) {
      SelectionChange<T> value = _selectionChanges[key];
      bool selected = value.isSelected();

      T oldValue = selectedSet[key];
      if (selected) {
        selectedSet[key] = value.getItem();
        Object oldKey = getKey(oldValue);
        if (!changed) {
          changed = (oldKey == null) ? (key != null) : oldKey != key;
        }
      } else {
        if (oldValue != null) {
          selectedSet.remove(key);
          changed = true;
        }
      }
    }
    _selectionChanges.clear();

    // Fire a selection change event.
    if (changed) {
      SelectionChangeEvent.fire(this);
    }
  }
}

/**
 * Stores an item and its pending selection state.
 * 
 * @param <T> the data type of the item
 */
class SelectionChange<T> {
  final T _item;
  final bool _isSelected;

  SelectionChange(this._item, this._isSelected);
  
  T getItem() {
    return _item;
  }

  bool isSelected() {
    return _isSelected;
  }
}
