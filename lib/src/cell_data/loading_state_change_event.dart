//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * An event used to indicate that the data loading state has changed.
 */
class LoadingStateChangeEvent extends event.DwtEvent {

  /**
   * A singleton instance of Type.
   */
  static event.EventType<LoadingStateChangeEventHandler> TYPE = new event.EventType<LoadingStateChangeEventHandler>();

  final LoadingState _state;

  /**
   * Construct a new {@link LoadingStateChangeEvent}.
   * 
   * @param _state the new _state
   */
  LoadingStateChangeEvent(this._state);

  event.EventType<LoadingStateChangeEventHandler> getAssociatedType() {
    return TYPE;
  }

  /**
   * Get the new {@link LoadingState} associated with this event.
   * 
   * @return the {@link LoadingState}
   */
  LoadingState getLoadingState() {
    return _state;
  }

  void dispatch(LoadingStateChangeEventHandler handler) {
    handler.onLoadingStateChanged(this);
  }
}


/**
 * Implemented by handlers of {@link LoadingStateChangeEvent}.
 */
abstract class LoadingStateChangeEventHandler extends event.EventHandler {
  /**
   * Called when a {@link LoadingStateChangeEvent} is fired.
   * 
   * @param event the {@link LoadingStateChangeEvent}
   */
  void onLoadingStateChanged(LoadingStateChangeEvent evt);
}

/**
 * Represents the current status of the data being loaded.
 */
class LoadingState extends util.Enum<int> {
  
  const LoadingState(int type) : super(type);

  /**
   * Indicates that the data has started to load.
   */
  static const LoadingState LOADING = const LoadingState(0);

  /**
   * Indicates that part of the data set has been loaded, but more data is
   * still pending.
   */
  static const LoadingState PARTIALLY_LOADED = const LoadingState(1);

  /**
   * Indicates that the data set has been completely loaded.
   */
  static const LoadingState LOADED = const LoadingState(3);
}