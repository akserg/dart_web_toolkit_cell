//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * A concrete subclass of {@link AbstractDataProvider} that is backed by an
 * in-memory list.
 * 
 * <p>
 * Modifications (inserts, removes, sets, etc.) to the list returned by
 * {@link #getList()} will be reflected in the model. However, mutations to the
 * items contained within the list will NOT be reflected in the model. You must
 * call {@link List#set(int, Object)} to update the item within the list and
 * push the change to the display, or call {@link #refresh()} to push all rows
 * to the displays. {@link List#set(int, Object)} performs better because it
 * allows the data provider to push only those rows which have changed, and
 * usually allows the display to re-render only a subset of the rows.
 * </p>
 * 
 * <p>
 * <h3>Example</h3> {@example
 * com.google.gwt.examples.view.ListDataProviderExample}
 * </p>
 * 
 * @param <T> the data type of the list
 */
class ListDataProvider<T> extends AbstractDataProvider<T> {

  /**
   * The wrapper around the actual list.
   */
  _ListWrapper _listWrapper;

  /**
   * Creates a list model that wraps the given list.
   * 
   * <p>
   * The wrapped list should no longer be modified as the data provider cannot
   * detect changes to the wrapped list. Instead, call {@link #getList()} to
   * retrieve a wrapper that can be modified and will correctly forward changes
   * to displays.
   * 
   * @param listToWrap the List to be wrapped
   * @param keyProvider an instance of data.ProvidesKey<T>, or null if the record
   *        object should act as its own key
   */
  ListDataProvider([List<T> listToWrap = null, data.ProvidesKey<T> keyProvider = null]) : super(keyProvider) {
    if (listToWrap == null) {
      listToWrap = new List<T>();
    }
    _listWrapper = new _ListWrapper(this, listToWrap);
  }

  /**
   * Flush pending list changes to the displays. By default, displays are
   * informed of modifications to the underlying list at the end of the current
   * event loop, which makes it possible to perform multiple operations
   * synchronously without repeatedly refreshing the displays. This method can
   * be called to flush the changes immediately instead of waiting until the end
   * of the current event loop.
   */
  void flush() {
    _listWrapper._flushNow();
  }

  /**
   * Get the list that backs this model. Changes to the list will be reflected
   * in the model.
   * 
   * <p>
   * NOTE: Mutations to the items contained within the list will NOT be
   * reflected in the model. You must call {@link List#set(int, Object)} to
   * update the item within the list and push the change to the display, or call
   * {@link #refresh()} to push all rows to the displays.
   * {@link List#set(int, Object)} performs better because it allows the data
   * provider to push only those rows which have changed, and usually allows the
   * display to re-render only a subset of the rows.
   * 
   * @return the list
   * 
   * @see #setList(List)
   */
  List<T> getList() {
    return _listWrapper.getList();
  }

  /**
   * Refresh all of the displays listening to this adapter.
   * 
   * <p>
   * Use {@link #refresh()} to push mutations to the underlying data items
   * contained within the list. The data provider cannot detect changes to data
   * objects within the list, so you must call this method if you modify items.
   * 
   * <p>
   * This is a shortcut for calling {@link List#set(int, Object)} on every item
   * that you modify, but note that calling {@link List#set(int, Object)}
   * performs better because the data provider knows which rows were modified
   * and can push only the modified rows the the displays.
   */
  void refresh() {
    updateAllRowData(0, _listWrapper.getList());
  }

  /**
   * Replace this model's list with the specified list.
   * 
   * <p>
   * The wrapped list should no longer be modified as the data provider cannot
   * detect changes to the wrapped list. Instead, call {@link #getList()} to
   * retrieve a wrapper that can be modified and will correctly forward changes
   * to displays.
   * 
   * @param listToWrap the model's new list
   * 
   * @see #getList()
   */
  void setList(List<T> listToWrap) {
    _listWrapper = new _ListWrapper(this, listToWrap);
    _listWrapper._minModified = 0;
    _listWrapper._maxModified = _listWrapper.size();
    _listWrapper._modified = true;
    flush();
  }

  
  void onRangeChanged(HasData<T> display) {
    int size = _listWrapper.size();
    if (size > 0) {
      // Do not push data if the data set is empty.
      updateRowData(display, 0, _listWrapper.getList());
    }
  }
}


///**
// * A wrapped ListIterator.
// */
//class WrappedListIterator implements ListIterator<T> {
//
//  /**
//   * The error message when {@link #add(Object)} or {@link #remove()} is
//   * called more than once per call to {@link #next()} or
//   * {@link #previous()}.
//   */
//  private static final String IMPERMEABLE_EXCEPTION =
//      "Cannot call add/remove more than once per call to next/previous.";
//
//  /**
//   * The index of the object that will be returned by {@link #next()}.
//   */
//  private int i = 0;
//
//  /**
//   * The index of the last object accessed through {@link #next()} or
//   * {@link #previous()}.
//   */
//  private int last = -1;
//
//  private WrappedListIterator() {
//  }
//
//  private WrappedListIterator(int start) {
//    int size = _ListWrapper.this.size();
//    if (start < 0 || start > size) {
//      throw new IndexOutOfBoundsException(
//          "Index: " + start + ", Size: " + size);
//    }
//    i = start;
//  }
//
//  
//  void add(T o) {
//    if (last < 0) {
//      throw new IllegalStateException(IMPERMEABLE_EXCEPTION);
//    }
//    _ListWrapper.this.add(i++, o);
//    last = -1;
//  }
//
//  
//  bool hasNext() {
//    return i < _ListWrapper.this.size();
//  }
//
//  
//  bool hasPrevious() {
//    return i > 0;
//  }
//
//  
//  T next() {
//    if (!hasNext()) {
//      throw new NoSuchElementException();
//    }
//    return _ListWrapper.this.get(last = i++);
//  }
//
//  
//  int nextIndex() {
//    return i;
//  }
//
//  
//  T previous() {
//    if (!hasPrevious()) {
//      throw new NoSuchElementException();
//    }
//    return _ListWrapper.this.get(last = --i);
//  }
//
//  
//  int previousIndex() {
//    return i - 1;
//  }
//
//  
//  void remove() {
//    if (last < 0) {
//      throw new IllegalStateException(IMPERMEABLE_EXCEPTION);
//    }
//    _ListWrapper.this.remove(last);
//    i = last;
//    last = -1;
//  }
//
//  
//  void set(T o) {
//    if (last == -1) {
//      throw new IllegalStateException();
//    }
//    _ListWrapper.this.set(last, o);
//  }
//}


/**
 * A wrapper around a list that updates the model on any change.
 */
class _ListWrapper<T> { // implements List<T> {

  ListDataProvider _dataProvider;
  
  /**
   * The current size of the list.
   */
  int _curSize = 0;

  /**
   * The delegate wrapper.
   */
  final _ListWrapper _delegate;

  /**
   * Set to true if the pending flush has been canceled.
   */
  bool _flushCancelled = false;

  /**
   * We wait until the end of the current event loop before flushing changes
   * so that we don't spam the displays. This also allows users to clear and
   * replace all of the data without forcing the display back to page 0.
   */
  scheduler.ScheduledCommand _flushCommand;

  /**
   * Set to true if a flush is pending.
   */
  bool _flushPending = false;

  /**
   * The list that backs the wrapper.
   */
  List<T> _list;

  /**
   * If this is a sublist, the offset it the index relative to the main list.
   */
  final int _offset;

  /**
   * If modified is true, the smallest modified index.
   */
  int _maxModified = MIN_VALUE;

  /**
   * If modified is true, one past the largest modified index.
   */
  int _minModified = MAX_VALUE;

  /**
   * True if the list data has been modified.
   */
  bool _modified = false;

  /**
   * Construct a new {@link _ListWrapper} that delegates flush calls to the
   * specified delegate.
  *
   * @param list the list to wrap
   * @param delegate the delegate
   * @param offset the offset of this list
   */
  _ListWrapper(this._dataProvider, this._list, [this._delegate = null, this._offset = 0]) {
    _flushCommand = new _ListWrapperScheduledCommand(this);
    // Initialize the data size based on the size of the input list.
    _dataProvider.updateRowCount(_list.length, true);
  }

  
  void insert(int index, T element) {
    try {
      _list.insert(index, element);
      _minModified = math.min(_minModified, index);
      _maxModified = size();
      _modified = true;
      _flush();
    } on Exception catch(e) {
      throw new Exception("IndexOutOfBoundsException: %e");
    }
  }

  
  bool add(T e) {
    _list.add(e);
    _minModified = math.min(_minModified, size() - 1);
    _maxModified = size();
    _modified = true;
    _flush();
    return true;
  }

  
  bool addAll(Iterable<T> c) {
    _minModified = math.min(_minModified, size());
    _list.addAll(c);
    _maxModified = size();
    _modified = true;
    _flush();
    return true;
  }

  
  bool insertAll(int index, Iterable<T> c) {
    try {
      _list.insertAll(index, c);
      _minModified = math.min(_minModified, index);
      _maxModified = size();
      _modified = true;
      _flush();
      return true;
    } on Exception catch (e) {
      throw new Exception("IndexOutOfBoundsException: %e");
    }
  }

  
  void clear() {
    _list.clear();
    _minModified = _maxModified = 0;
    _modified = true;
    _flush();
  }

  
  bool contains(Object o) {
    return _list.contains(o);
  }

  
  bool containsAll(Iterable c) {
    for (var item in c) {
      if (!_list.contains(item))
        return false;
    }
    return true;
  }

  
  bool equals(Object o) {
    return _list == o;
  }

  
  T get(int index) {
    return _list[index];
  }

  
//  int hashCode() {
//    return _list.hashCode();
//  }

  
  int indexOf(Object o) {
    return _list.indexOf(o);
  }

  
  bool isEmpty() {
    return _list.isEmpty;
  }

  
//  Iterator<T> iterator() {
//    return listIterator();
//  }

  
  int lastIndexOf(Object o) {
    return _list.lastIndexOf(o);
  }

  
//  ListIterator<T> listIterator() {
//    return new WrappedListIterator();
//  }
//
//  
//  ListIterator<T> listIterator(int index) {
//    return new WrappedListIterator(index);
//  }

  
  T removeAt(int index) {
    try {
      T toRet = _list.remove(index);
      _minModified = math.min(_minModified, index);
      _maxModified = size();
      _modified = true;
      _flush();
      return toRet;
    } on Exception catch (e) {
      throw new Exception("IndexOutOfBoundsException: %e");
    }
  }

  
  bool remove(Object o) {
    int index = indexOf(o);
    if (index == -1) {
      return false;
    }
    remove(index);
    return true;
  }

  
  bool removeAll(Iterable c) {
    bool toRet = true;
    
    for (var item in c) {
      if (_list.contains(item)) {
        toRet = toRet && _list.remove(c);
      } else {
        toRet = false;
      }
    }
    _minModified = 0;
    _maxModified = size();
    _modified = true;
    _flush();
    return toRet;
  }

  
  bool retainAll(Iterable c) {
    bool toRet = true;
    
    for (var item in c) {
      if (!_list.contains(item)) {
        toRet = toRet && _list.remove(c);
      }
    }
    _minModified = 0;
    _maxModified = size();
    _modified = true;
    _flush();
    return toRet;
  }

  
  T set(int index, T element) {
    T toRet = _list[index] = element;
    _minModified = math.min(_minModified, index);
    _maxModified = math.max(_maxModified, index + 1);
    _modified = true;
    _flush();
    return toRet;
  }

  
  int size() {
    return _list.length;
  }

  
  List<T> sublist(int fromIndex, int toIndex) {
    return new _ListWrapper(_dataProvider, _list.sublist(fromIndex, toIndex), this, fromIndex).getList();
  }

  
//  Object[] toArray() {
//    return _list.toArray();
//  }
//
//  
//  <C> C[] toArray(C[] a) {
//    return _list.toArray(a);
//  }

  /**
   * Flush the data to the model.
  */
  void _flush() {
    // Defer to the delegate.
    if (_delegate != null) {
      _delegate._minModified = math.min(_minModified + _offset, _delegate._minModified);
      _delegate._maxModified = math.max(_maxModified + _offset, _delegate._maxModified);
      _delegate._modified = _modified || _delegate._modified;
      _delegate._flush();
      return;
    }

    _flushCancelled = false;
    if (!_flushPending) {
      _flushPending = true;
//      scheduler.Scheduler.get().scheduleFinally(_flushCommand);
      scheduler.Scheduler.get().scheduleDeferred(_flushCommand);
    }
  }

  /**
   * Flush pending list changes to the displays. By default,
   */
  void _flushNow() {
    // Cancel any pending flush command.
    if (_flushPending) {
      _flushCancelled = true;
    }

    // Early exit if this list has been replaced in the data provider.
    if (_dataProvider._listWrapper != this) {
      return;
    }

    int newSize = _list.length;
    if (_curSize != newSize) {
      _curSize = newSize;
      _dataProvider.updateRowCount(_curSize, true);
    }

    if (_modified) {
      _dataProvider.updateAllRowData(_minModified, _list.sublist(_minModified, _maxModified));
      _modified = false;
    }
    _minModified = MAX_VALUE;
    _maxModified = MIN_VALUE;
  }
  
  List<T> getList() {
    return _list;
  }
}


class _ListWrapperScheduledCommand implements scheduler.ScheduledCommand {
  
  _ListWrapper _wrapper;
  
  _ListWrapperScheduledCommand(this._wrapper);
  
  void execute() {
    _wrapper._flushPending = false;
    if (_wrapper._flushCancelled) {
      _wrapper._flushCancelled = false;
      return;
    }
    _wrapper._flushNow();
  }
}