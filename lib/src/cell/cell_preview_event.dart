//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell;

/**
 * Allows the previewing of events before they are fired to Cells.
 * 
 * @param <T> the data type of the {@link HasData} source
 */
class CellPreviewEvent<T> extends event.DwtEvent<T> {

  /**
   * Handler type.
   */
  static event.EventType<CellPreviewEventHandler> TYPE = new event.EventType<CellPreviewEventHandler>();
  
  /**
   * Returns the [EventType] used to register this event, allowing an
   * [EventBus] to find handlers of the appropriate class.
   *
   * @return the type
   */
  event.EventType<CellPreviewEventHandler> getAssociatedType() {
    return TYPE;
  }
  
  /**
   * Fires a cell preview event on all registered handlers in the handler
   * manager. If no such handlers exist, this implementation will do nothing.
   * This implementation sets the column to 0.
   * 
   * @param <T> the old value type
   * @param source the source of the handlers
   * @param nativeEvent the event to preview
   * @param display the {@link HasData} source of the event
   * @param context the Cell {@link CellContext}
   * @param value the value where the event occurred
   * @param isCellEditing indicates whether or not the cell is being edited
   * @param isSelectionHandled indicates whether or not selection is handled
   * @return the {@link CellPreviewEvent} that was fired
   */
  static CellPreviewEvent fire(HasCellPreviewHandlers source,
      dart_html.Event nativeEvent, HasData display, CellContext context, value,
      bool isCellEditing, bool isSelectionHandled) {
    CellPreviewEvent evt = new CellPreviewEvent(nativeEvent, display,
        context, value, isCellEditing, isSelectionHandled);
      source.fireEvent(evt);
    return evt;
  }

  final CellContext _context;
  final HasData<T> _display;
  bool _isCanceled = false;
  final bool _isCellEditing;
  final bool _isSelectionHandled;
  final dart_html.Event _nativeEvent;
  final T _value;

  /**
   * Construct a new {@link CellPreviewEvent}.
   * 
   * @param _nativeEvent the event to preview
   * @param _display the {@link HasData} source of the event
   * @param _context the Cell {@link CellContext}
   * @param _value the _value where the event occurred
   * @param _isCellEditing indicates whether or not the cell is being edited
   * @param _isSelectionHandled indicates whether or not selection is handled
   */
  CellPreviewEvent(this._nativeEvent, this._display,
      this._context, this._value, this._isCellEditing,
      this._isSelectionHandled);

//  // The instance knows its Handler is of type T, but the TYPE
//  // field itself does not, so we have to do an unsafe cast here.
//  @SuppressWarnings({"unchecked", "rawtypes"})
//  
//  Type<Handler<T>> getAssociatedType() {
//    return (Type) TYPE;
//  }

  /**
   * Get the column index of the Cell where the event occurred if the source is
   * a table. If the source is not a table, the column is always 0.
   * 
   * @return the column index, or 0 if there is only one column
   */
  int getColumn() {
    return _context.getColumn();
  }

  /**
   * Get the cell {@link CellContext}.
   * 
   * @return the cell {@link CellContext}
   */
  CellContext getContext() {
    return _context;
  }

  /**
   * Get the {@link HasData} source of the event.
   */
  HasData<T> getDisplay() {
    return _display;
  }

  /**
   * Get the index of the _value where the event occurred.
   */
  int getIndex() {
    return _context.getIndex();
  }

  /**
   * Get the {@link dart_html.Event} to preview.
   */
  dart_html.Event getNativeEvent() {
    return _nativeEvent;
  }

  /**
   * Get the _value where the event occurred.
   */
  T getValue() {
    return _value;
  }

  /**
   * Check if the event has been canceled.
   * 
   * @return true if the event has been canceled
   * @see #setCanceled(bool)
   */
  bool isCanceled() {
    return _isCanceled;
  }

  /**
   * Check whether or not the cell where the event occurred is being edited.
   * 
   * @return true if the cell is being edited, false if not
   */
  bool isCellEditing() {
    return _isCellEditing;
  }

  /**
   * Check whether or not selection is being handled by the widget or one of its
   * Cells.
   * 
   * @return true if selection is handled by the widget
   */
  bool isSelectionHandled() {
    return _isSelectionHandled;
  }

  /**
   * Cancel the event and prevent it from firing to the Cell.
   * 
   * @param cancel true to cancel the event, false to allow it
   */
  void setCanceled(bool cancel) {
    this._isCanceled = cancel;
  }

  void dispatch(CellPreviewEventHandler<T> handler) {
    handler.onCellPreview(this);
  }
}

/**
 * Handler for {@link CellPreviewEvent}.
 * 
 * @param <T> the data type of the {@link HasData}
 */
abstract class CellPreviewEventHandler<T> extends event.EventHandler {

  /**
   * Called when {@link CellPreviewEvent} is fired.
   * 
   * @param event the {@link CellPreviewEvent} that was fired
   */
  void onCellPreview(CellPreviewEvent<T> evt);
}