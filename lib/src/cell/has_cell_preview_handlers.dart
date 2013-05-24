//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell;

/**
 * A widget that implements this interface is a public source of
 * {@link CellPreviewEvent} events.
 * 
 * @param <T> the data type of the values in the widget
 */
abstract class HasCellPreviewHandlers<T> extends event.HasHandlers {
  /**
   * Adds a {@link CellPreviewEvent} handler.
   * 
   * @param handler the handler
   * @return the registration for the event
   */
  event.HandlerRegistration addCellPreviewHandler(CellPreviewEventHandler<T> handler);
}