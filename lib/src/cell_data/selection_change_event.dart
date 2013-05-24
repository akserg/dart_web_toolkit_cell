//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * Represents a selection change event.
 */
class SelectionChangeEvent extends event.DwtEvent {

  /**
   * Handler type.
   */
  static event.EventType<SelectionChangeEventHandler> TYPE = new event.EventType<SelectionChangeEventHandler>();

  /**
   * Returns the [EventType] used to register this event, allowing an
   * [EventBus] to find handlers of the appropriate class.
   *
   * @return the type
   */
  event.EventType<SelectionChangeEventHandler> getAssociatedType() {
    return TYPE;
  }
  
  /**
   * Fires a selection change event on all registered handlers in the handler
   * manager. If no such handlers exist, this method will do nothing.
   *
   * @param source the source of the handlers
   */
  static void fire(HasSelectionChangedHandlers source) {
    SelectionChangeEvent event = new SelectionChangeEvent();
    source.fireEvent(event);
  }

  /**
   * Creates a selection change event.
   */
  SelectionChangeEvent();

  void dispatch(SelectionChangeEventHandler handler) {
    handler.onSelectionChange(this);
  }
}

/**
 * Handler interface for {@link SelectionChangeEvent} events.
 */
abstract class SelectionChangeEventHandler extends event.EventHandler {

  /**
   * Called when a {@link SelectionChangeEvent} is fired.
  *
   * @param event the {@link SelectionChangeEvent} that was fired
   */
  void onSelectionChange(SelectionChangeEvent evt);
}

/**
 * Interface specifying that a class can add
 * {@code SelectionChangeEvent.Handler}s.
 */
abstract class HasSelectionChangedHandlers extends event.HasHandlers {
  /**
   * Adds a {@link SelectionChangeEvent} handler.
   * 
   * @param handler the handler
   * @return {@link HandlerRegistration} used to remove this handler
   */
  event.HandlerRegistration addSelectionChangeHandler(SelectionChangeEventHandler handler);
}