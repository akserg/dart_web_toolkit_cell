//Copyright (C) 2013 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

/**
 * Data presentation widgets for the Dart Web Toolkit.
 */
part of dart_web_toolkit_cell_data;

/**
 * A model that allows getting all elements and clearing the selection.
 *
 * @param <T> the record data type
 */
abstract class SetSelectionModel<T> extends SelectionModel<T> {
  
  /**
   * Clears the current selection.
   */
  void clear();

  /**
   * Get the set of selected items.
   *
   * @return the set of selected items
   */
  Set<T> getSelectedSet();
}
