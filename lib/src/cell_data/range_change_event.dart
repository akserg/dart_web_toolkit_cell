//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * Represents a range change event.
 */
class RangeChangeEvent extends event.DwtEvent {

  /**
   * Handler type.
   */
  static event.EventType<RangeChangeEventHandler> TYPE = new event.EventType<RangeChangeEventHandler>();

  /**
   * Returns the [EventType] used to register this event, allowing an
   * [EventBus] to find handlers of the appropriate class.
   *
   * @return the type
   */
  event.EventType<RangeChangeEventHandler> getAssociatedType() {
    return TYPE;
  }
  
  /**
   * Fires a {@link RangeChangeEvent} on all registered handlers in the handler
   * manager. If no such handlers exist, this method will do nothing.
   *
   * @param source the source of the handlers
   * @param range the new range
   */
  static void fire(HasRows source, Range range) {
    RangeChangeEvent event = new RangeChangeEvent(range);
    source.fireEvent(event);
  }

  final Range _range;

  /**
   * Creates a {@link RangeChangeEvent}.
   *
   * @param range the new range
   */
  RangeChangeEvent(this._range);

  /**
   * Gets the new range.
   *
   * @return the new range
   */
  Range getNewRange() {
    return _range;
  }

  void dispatch(RangeChangeEventHandler handler) {
    handler.onRangeChange(this);
  }
}

/**
 * Handler interface for {@link RangeChangeEvent} events.
 */
abstract class RangeChangeEventHandler extends event.EventHandler {

  /**
   * Called when a {@link RangeChangeEvent} is fired.
  *
   * @param event the {@link RangeChangeEvent} that was fired
   */
  void onRangeChange(RangeChangeEvent event);
}