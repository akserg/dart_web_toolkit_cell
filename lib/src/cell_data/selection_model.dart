//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * A model for selection within a list.
 * 
 * @param <T> the data type of records in the list
 */
abstract class SelectionModel<T> implements HasSelectionChangedHandlers, data.ProvidesKey<T> {

  /**
   * Adds a {@link SelectionChangeEvent} handler.
   * 
   * @param handler the handler
   * @return the registration for the event
   */
  event.HandlerRegistration addSelectionChangeHandler(SelectionChangeEventHandler handler);

  /**
   * Check if an object is selected.
   * 
   * @param object the object
   * @return true if selected, false if not
   */
  bool isSelected(T object);

  /**
   * Set the selected state of an object and fire a
   * {@link SelectionChangeEvent} if the selection has
   * changed.  Subclasses should not fire an event in the case where
   * selected is true and the object was already selected, or selected
   * is false and the object was not previously selected.
   * 
   * @param object the object to select or deselect
   * @param selected true to select, false to deselect
   */
  void setSelected(T object, bool selected);
}

/**
 * A default implementation of {@link SelectionModel} that provides listener
 * addition and removal.
 * 
 * @param <T> the data type of records in the list
 */
abstract class AbstractSelectionModel<T> implements SelectionModel<T> {

  event.EventBus _handlerManager = new event.SimpleEventBus();

  /**
   * Set to true if the next scheduled event should be canceled.
   */
  bool _isEventCancelled;

  /**
   * Set to true if an event is scheduled to be fired.
   */
  bool _isEventScheduled;

  final data.ProvidesKey<T> _keyProvider;
  
  /**
   * Construct an AbstractSelectionModel with a given key provider.
   * 
   * @param _keyProvider an instance of ProvidesKey<T>, or null if the record
   *        object should act as its own key
   */
  AbstractSelectionModel(this._keyProvider);

  
  event.HandlerRegistration addSelectionChangeHandler(SelectionChangeEventHandler handler) {
    return _handlerManager.addHandler(SelectionChangeEvent.TYPE, handler);
  }

  
  void fireEvent(event.DwtEvent evt) {
    _handlerManager.fireEvent(evt);
  }

  
  Object getKey(T item) {
    return (_keyProvider == null || item == null) ? item
        : _keyProvider.getKey(item);
  }

  /**
   * Returns a {@link ProvidesKey} instance that simply returns the input data
   * item.
  *
   * @return the key provider, which may be null
   */
  data.ProvidesKey<T> getKeyProvider() {
    return _keyProvider;
  }

  /**
   * Fire a {@link SelectionChangeEvent}.  Multiple firings may be coalesced.
   */
  void fireSelectionChangeEvent() {
    if (isEventScheduled()) {
      setEventCancelled(true);
    }
    SelectionChangeEvent.fire(this);
  }

  /**
   * Return true if the next scheduled event should be canceled.
  *
   * @return true if the event is canceled
   */
  bool isEventCancelled() {
    return _isEventCancelled;
  }

  /**
   * Return true if an event is scheduled to be fired.
  *
   * @return true if the event is scheduled
   */
  bool isEventScheduled() {
    return _isEventScheduled;
  }

  /**
   * Schedules a {@link SelectionChangeEvent} to fire at the
   * end of the current event loop.
   */
  void scheduleSelectionChangeEvent() {
    setEventCancelled(false);
    if (!isEventScheduled()) {
      setEventScheduled(true);
//      scheduler.Scheduler.get().scheduleFinally(new _SelectionModelScheduledCommand(this));
      scheduler.Scheduler.get().scheduleDeferred(new _SelectionModelScheduledCommand(this));
    }
  }

  /**
   * Set whether the next scheduled event should be canceled.
   * 
   * @param isEventCancelled if true, cancel the event
   */
  void setEventCancelled(bool isEventCancelled) {
    this._isEventCancelled = isEventCancelled;
  }

  /**
   * Set whether an event is scheduled to be fired.
   * 
   * @param isEventScheduled if true, schedule the event
   */
  void setEventScheduled(bool isEventScheduled) {
    this._isEventScheduled = isEventScheduled;
  }
}

class _SelectionModelScheduledCommand extends scheduler.ScheduledCommand {
  
  AbstractSelectionModel _model;
  
  _SelectionModelScheduledCommand(this._model);
  
  void execute() {
    _model.setEventScheduled(false);
    if (_model.isEventCancelled()) {
      _model.setEventCancelled(false);
      return;
    }
    _model.fireSelectionChangeEvent();
  }
}