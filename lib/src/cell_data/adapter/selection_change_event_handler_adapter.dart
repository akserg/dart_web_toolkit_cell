//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * Handler interface for {@link SelectionChangeEvent} events.
 */
class SelectionChangeEventHandlerAdapter extends event.EventHandlerAdapter implements SelectionChangeEventHandler {

  SelectionChangeEventHandlerAdapter(event.EventHandlerAdapterCallback callback) : super(callback);

  /**
   * Called when a {@link SelectionChangeEvent} is fired.
   *
   * @param event the {@link SelectionChangeEvent} that was fired
   */
  void onSelectionChange(SelectionChangeEvent evt) {
    callback(evt);
  }
}