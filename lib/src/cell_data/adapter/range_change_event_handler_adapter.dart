//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * Handler interface for {@link RangeChangeEvent} events.
 */
class RangeChangeEventHandlerAdapter extends event.EventHandlerAdapter implements RangeChangeEventHandler {

  RangeChangeEventHandlerAdapter(event.EventHandlerAdapterCallback callback) : super(callback);

  /**
   * Called when a {@link RangeChangeEvent} is fired.
   *
   * @param event the {@link RangeChangeEvent} that was fired
   */
  void onRangeChange(RangeChangeEvent evt) {
    callback(evt);
  }
}