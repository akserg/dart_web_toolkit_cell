//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * Represents a row count change event.
 */
class RowCountChangeEvent extends event.DwtEvent {

  /**
   * Handler type.
   */
  static event.EventType<RowCountChangeEventHandler> TYPE = new event.EventType<RowCountChangeEventHandler>();

  /**
   * Returns the [EventType] used to register this event, allowing an
   * [EventBus] to find handlers of the appropriate class.
   *
   * @return the type
   */
  event.EventType<RowCountChangeEventHandler> getAssociatedType() {
    return TYPE;
  }
  
  /**
   * Fires a {@link RowCountChangeEvent} on all registered handlers in the
   * handler manager. If no such handlers exist, this method will do nothing.
   *
   * @param source the source of the handlers
   * @param rowCount the new rowCount
   * @param isExact true if rowCount is an exact count
   */
  static void fire(HasRows source, int rowCount, bool isExact) {
    RowCountChangeEvent event = new RowCountChangeEvent(rowCount, isExact);
    source.fireEvent(event);
  }

  final int _rowCount;
  final bool _isExact;

  /**
   * Creates a {@link RowCountChangeEvent}.
   *
   * @param _rowCount the new row count
   * @param _isExact true if the row count is exact
   */
  RowCountChangeEvent(this._rowCount, this._isExact);

  /**
   * Gets the new row count.
   *
   * @return the new row count
   */
  int getNewRowCount() {
    return _rowCount;
  }

  /**
   * Check if the new row count is exact.
   *
   * @return true if the new row count is exact, false if not
   */
  bool isNewRowCountExact() {
    return _isExact;
  }

  void dispatch(RowCountChangeEventHandler handler) {
    handler.onRowCountChange(this);
  }
}

/**
 * Handler interface for {@link RowCountChangeEvent} events.
 */
abstract class RowCountChangeEventHandler extends event.EventHandler {

  /**
   * Called when a {@link RowCountChangeEvent} is fired.
  *
   * @param event the {@link RowCountChangeEvent} that was fired
   */
  void onRowCountChange(RowCountChangeEvent evt);
}