//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * A base implementation of a data source for {@link HasData} implementations.
 *
 * @param <T> the data type of records in the list
 */
abstract class AbstractDataProvider<T> implements data.ProvidesKey<T> {

  Set<HasData<T>> _displays = new Set<HasData<T>>();

  /**
   * The provider of keys for list items.
   */
  final data.ProvidesKey<T> _keyProvider;

  /**
   * The last row count.
   */
  int _lastRowCount = -1;

  /**
   * Indicates whether or not the last row count is exact.
   */
  bool _lastRowCountExact;

  /**
   * A mapping of {@link HasData}s to their handlers.
   */
  Map<HasData<T>, event.HandlerRegistration> _rangeChangeHandlers =
      new Map<HasData<T>, event.HandlerRegistration>();
  
  /**
   * Construct an AbstractDataProvider with a given key provider.
   * 
   * @param keyProvider a {@link data.ProvidesKey} object
   */
  AbstractDataProvider([this._keyProvider = null]);

  /**
   * Adds a data display to this adapter. The current range of interest of the
   * display will be populated with data.
   *
   * @param display a {@link HasData}.
   */
  void addDataDisplay(final HasData<T> display) {
    if (display == null) {
      throw new Exception("display cannot be null");
    } else if (_displays.contains(display)) {
      throw new Exception(
          "The specified display has already been added to this adapter.");
    }

    // Add the display to the set.
    _displays.add(display);

    // Add a handler to the display.
    event.HandlerRegistration handler = display.addRangeChangeHandler(
        new RangeChangeEventHandlerAdapter((RangeChangeEvent event) {
            onRangeChanged(display);
        }));
    _rangeChangeHandlers[display] = handler;

    // Update the data size in the display.
    if (_lastRowCount >= 0) {
      display.setRowCount(_lastRowCount, _lastRowCountExact);
    }

    // Initialize the display with the current range.
    onRangeChanged(display);
  }

  /**
   * Get the set of displays currently assigned to this adapter.
   *
   * @return the set of {@link HasData}
   */
  Set<HasData<T>> getDataDisplays() {
    return new Set<HasData<T>>.from(_displays);
  }

  /**
   * Get the key for a list item. The default implementation returns the item
   * itself.
   *
   * @param item the list item
   * @return the key that represents the item
   */
  Object getKey(T item) {
    return _keyProvider == null ? item : _keyProvider.getKey(item);
  }

  /**
   * Get the {@link data.ProvidesKey} that provides keys for list items.
   *
   * @return the {@link data.ProvidesKey}
   */
  data.ProvidesKey<T> getKeyProvider() {
    return _keyProvider;
  }

  /**
   * Get the current ranges of all displays.
   *
   * @return the ranges
   */
  List<Range> getRanges() {
    List<Range> ranges = new List<Range>(_displays.length);
    int i = 0;
    for (HasData<T> display in _displays) {
      ranges[i++] = display.getVisibleRange();
    }
    return ranges;
  }

  /**
   * Remove the given data display.
   * 
   * @param display a {@link HasData} instance
   * 
   * @throws IllegalStateException if the display is not present
   */
  void removeDataDisplay(HasData<T> display) {
    if (!_displays.contains(display)) {
      throw new Exception("HasData not present");
    }
    _displays.remove(display);

    // Remove the handler.
    event.HandlerRegistration handler = _rangeChangeHandlers.remove(display);
    handler.removeHandler();
  }

  /**
   * Called when a display changes its range of interest.
   *
   * @param display the display whose range has changed
   */
  void onRangeChanged(HasData<T> display);

  /**
   * Inform the displays of the total number of items that are available.
   *
   * @param count the new total row count
   * @param exact true if the count is exact, false if it is an estimate
   */
  void updateRowCount(int count, bool exact) {
    _lastRowCount = count;
    _lastRowCountExact = exact;

    for (HasData<T> display in _displays) {
      display.setRowCount(count, exact);
    }
  }

  /**
   * Inform the displays of the new data.
   *
   * @param start the start index
   * @param values the data values
   */
  void updateAllRowData(int start, List<T> values) {
    for (HasData<T> display in _displays) {
      updateRowData(display, start, values);
    }
  }

  /**
   * Informs a single display of new data.
   *
   * @param display the display to be updated
   * @param start the start index
   * @param values the data values
   */
  void updateRowData(HasData<T> display, int start, List<T> values) {
    int end = start + values.length;
    Range range = display.getVisibleRange();
    int curStart = range.getStart();
    int curLength = range.getLength();
    int curEnd = curStart + curLength;
    if (start == curStart || (curStart < end && curEnd > start)) {
      // Fire the handler with the data that is in the range.
      // Allow an empty list that starts on the page start.
      int realStart = curStart < start ? start : curStart;
      int realEnd = curEnd > end ? end : curEnd;
      int realLength = realEnd - realStart;
      List<T> realValues = values.sublist(
          realStart - start, realStart - start + realLength);
      display.setRowData(realValues, realStart);
    }
  }
}
